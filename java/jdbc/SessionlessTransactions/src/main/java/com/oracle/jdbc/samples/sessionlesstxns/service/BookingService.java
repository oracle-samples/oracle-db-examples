package com.oracle.jdbc.samples.sessionlesstxns.service;

import com.oracle.jdbc.samples.sessionlesstxns.dto.CheckoutRequestDTO;
import com.oracle.jdbc.samples.sessionlesstxns.dto.CheckoutResponseDTO;
import com.oracle.jdbc.samples.sessionlesstxns.dto.StartTransactionRequestDTO;
import com.oracle.jdbc.samples.sessionlesstxns.dto.RequestTicketsRequestDTO;
import com.oracle.jdbc.samples.sessionlesstxns.dto.RequestTicketsResponseDTO;
import com.oracle.jdbc.samples.sessionlesstxns.dto.StartTransactionResponseDTO;
import com.oracle.jdbc.samples.sessionlesstxns.exception.APIException;
import com.oracle.jdbc.samples.sessionlesstxns.exception.BookingNotFoundException;
import com.oracle.jdbc.samples.sessionlesstxns.exception.NoFreeSeatFoundException;
import com.oracle.jdbc.samples.sessionlesstxns.exception.NoTicketFoundException;
import com.oracle.jdbc.samples.sessionlesstxns.exception.TransactionNotFoundException;
import com.oracle.jdbc.samples.sessionlesstxns.exception.UnexpectedException;
import com.oracle.jdbc.samples.sessionlesstxns.util.Util;
import oracle.jdbc.OracleConnection;
import oracle.jdbc.OraclePreparedStatement;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Savepoint;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

@Service
public class BookingService {
  DataSource connectionPool;
  PaymentService paymentService;
  static final int INTEGRITY_CONSTRAINT_ERROR = 2291;
  static final int TRANSACTION_NOT_FOUND_ERROR = 26218;

  public BookingService(DataSource dataSource, @SuppressWarnings("SpringJavaInjectionPointsAutowiringInspection") PaymentService paymentService) {
    this.connectionPool = dataSource;
    this.paymentService = paymentService;
  }

  public StartTransactionResponseDTO startTransaction(StartTransactionRequestDTO body) {
    try (OracleConnection conn = (OracleConnection) connectionPool.getConnection();
         AutoCloseable rollback = conn::rollback;) {
      conn.setAutoCommit(false);
      byte[] gtrid = conn.startTransaction(body.timeout() * 60);

      long bookingId = createBooking(conn);

      List<Long> seats = lockAndBookSeats(conn, bookingId, body.flightId(), body.count());
      conn.suspendTransaction();

      return new StartTransactionResponseDTO(bookingId, Util.byteArrayToHex(gtrid), seats.size(), seats);
    } catch (APIException ex) {
      throw ex;
    } catch (Exception ex) {
      throw new UnexpectedException(ex);
    }
  }

  public RequestTicketsResponseDTO requestTickets(Long bookingId, RequestTicketsRequestDTO body) {
    try (OracleConnection conn = (OracleConnection) connectionPool.getConnection();
         AutoCloseable suspend = conn::suspendTransaction;) {
      conn.setAutoCommit(false);

      conn.resumeTransaction(Util.hexToByteArray(body.transactionId()));

      List<Long> seats = lockAndBookSeats(conn, bookingId, body.flightId(), body.count());

      return new RequestTicketsResponseDTO(seats.size(), seats);
    } catch (SQLException ex) {
      if (ex.getErrorCode() == TRANSACTION_NOT_FOUND_ERROR) {
        throw new TransactionNotFoundException(body.transactionId());
      }
      throw new UnexpectedException(ex);
    } catch (APIException ex) {
      throw ex;
    } catch (Exception ex) {
      throw new UnexpectedException(ex);
    }
  }

  public void removeTicket(Long bookingId, Long seatId, String transactionId) {
    try (OracleConnection conn = (OracleConnection) connectionPool.getConnection();
         AutoCloseable suspend = conn::suspendTransaction;) {
      conn.setAutoCommit(false);
      conn.resumeTransaction(Util.hexToByteArray(transactionId));

      removeTicket(conn, seatId, bookingId);
    } catch (SQLException ex) {
      if (ex.getErrorCode() == TRANSACTION_NOT_FOUND_ERROR) {
        throw new TransactionNotFoundException(transactionId);
      }
      throw new UnexpectedException(ex);
    } catch (APIException ex) {
      throw ex;
    } catch (Exception ex) {
      throw new UnexpectedException(ex);
    }
  }

  public CheckoutResponseDTO checkout(Long bookingId, CheckoutRequestDTO checkoutDetails) {
    float sum;
    byte[] gtrid = Util.hexToByteArray(checkoutDetails.transactionId());
    String receipt;
    List<CheckoutResponseDTO.TicketDTO> tickets;

    try (OracleConnection conn = (OracleConnection) connectionPool.getConnection();) {
      conn.setAutoCommit(false);
      conn.resumeTransaction(gtrid);
      try {
        tickets = getTickets(conn, bookingId);
        sum = tickets.stream().map(CheckoutResponseDTO.TicketDTO::price).reduce(0F, Float::sum);
        receipt = paymentService.pay(sum, checkoutDetails.paymentMethod());
        saveReceipt(conn, receipt, sum, bookingId, checkoutDetails.paymentMethod());
      } catch (Exception ex) {
        conn.suspendTransaction();
        throw ex;
      }
      conn.commit();
    } catch (SQLException ex) {
      if (ex.getErrorCode() == TRANSACTION_NOT_FOUND_ERROR) {
        throw new TransactionNotFoundException(checkoutDetails.transactionId());
      }
      throw new UnexpectedException(ex);
    } catch (APIException ex) {
      throw ex;
    } catch (Exception ex) {
      throw new UnexpectedException(ex);
    }

    return new CheckoutResponseDTO(bookingId, tickets, sum, receipt, checkoutDetails.paymentMethod());
  }

  public void cancelBooking(String transactionId) {
    try (OracleConnection conn = (OracleConnection) connectionPool.getConnection();) {
      conn.setAutoCommit(false);
      conn.resumeTransaction(Util.hexToByteArray(transactionId));
      conn.rollback();
    } catch (SQLException ex) {
      if (ex.getErrorCode() == TRANSACTION_NOT_FOUND_ERROR) {
        throw new TransactionNotFoundException(transactionId);
      }
      throw new UnexpectedException(ex);
    } catch (APIException ex) {
      throw ex;
    } catch (Exception ex) {
      throw new UnexpectedException(ex);
    }
  }

  private List<Long> lockAndBookSeats(OracleConnection conn, long bookingId, long flightId, int count)
      throws SQLException, NoFreeSeatFoundException, BookingNotFoundException {
    Savepoint sp1 = conn.setSavepoint();
    try {
      List<Long> seats = getFreeSeats(conn, flightId, count);
      if (seats.isEmpty()) {
        throw new NoFreeSeatFoundException(flightId);
      }
      for (Long seatId : seats) {
        addTicket(conn, seatId, bookingId);
      }
      return seats;
    } catch (BookingNotFoundException ex) {
      conn.rollback(sp1);
      throw ex;
    }
  }

  private void saveReceipt(OracleConnection conn, String receiptNumber, double sum, long bookingId, long paymentMethodId)
          throws SQLException {
    final String saveReceiptDML = """
          INSERT INTO receipts (created_at, receipt_number, total, booking_id, payment_method_id) values (?, ?, ?, ?, ?);
    """;

    try (OraclePreparedStatement stmt = (OraclePreparedStatement) conn.prepareStatement(saveReceiptDML)) {
      stmt.setTimestamp(1, new Timestamp(System.currentTimeMillis()));
      stmt.setString(2, receiptNumber);
      stmt.setDouble(3, sum);
      stmt.setLong(4, bookingId);
      stmt.setLong(5, paymentMethodId);
      stmt.execute();
    } catch (SQLException ex) {
      if (ex.getErrorCode() == INTEGRITY_CONSTRAINT_ERROR) {
        throw new BookingNotFoundException(bookingId);
      }
      throw ex;
    }
  }

  private void addTicket(Connection conn, long seatId, long bookingId)
          throws SQLException, BookingNotFoundException {
    final String saveTicketDML = "INSERT INTO tickets (seat_id, booking_id) VALUES (?, ?)";
    try (PreparedStatement stmt = conn.prepareStatement(saveTicketDML)) {
      stmt.setLong(1, seatId);
      stmt.setLong(2, bookingId);
      stmt.execute();
    } catch (SQLException ex) {
      if (ex.getErrorCode() == INTEGRITY_CONSTRAINT_ERROR) {
        throw new BookingNotFoundException(bookingId);
      }
      throw ex;
    }

    final String updateSeatDML = "UPDATE seats SET available=FALSE WHERE id = ?";
    try(PreparedStatement stmt = conn.prepareStatement(updateSeatDML)) {
      stmt.setLong(1, seatId);
      stmt.execute();
    }
  }

  private void removeTicket(OracleConnection conn, long seatId, long bookingId)
      throws SQLException, NoTicketFoundException {
    final String deleteTicketDML = "DELETE FROM tickets WHERE seat_id = ? AND booking_id = ?";
    try (PreparedStatement stmt = conn.prepareStatement(deleteTicketDML)) {
      stmt.setLong(1, seatId);
      stmt.setLong(2, bookingId);
      if (stmt.executeUpdate() == 0) {
        throw new NoTicketFoundException(seatId, bookingId);
      }
    }

    // FIXME: The updated row would still be locked by the transaction until it is committed or rolledback.
    // Is there a way to work around this?
    final String updateSeatDML = "UPDATE seats SET available=TRUE WHERE id = ?";
    try (PreparedStatement stmt = conn.prepareStatement(updateSeatDML)) {
      stmt.setLong(1, seatId);
      stmt.executeUpdate();
    }
  }

  /**
   * Get free tickets from the database and lock them.
   *
   * @param conn db connection.
   * @param flightId flight ID.
   * @param count number of tickets to request.
   *
   * @return list of locked tickets, list size will be less or equal to {@code count} depending on the
   * availability of the tickets in the database.
   */
  private List<Long> getFreeSeats(OracleConnection conn, long flightId, int count) throws SQLException {
    final String getFreeSeatsQuery = """
      SELECT id FROM seats
      WHERE available = true AND flight_id = ?
      FETCH FIRST ? ROW ONLY
      FOR UPDATE SKIP LOCKED;""";

    List<Long> seats = new ArrayList<>();

    try(PreparedStatement stmt = conn.prepareStatement(getFreeSeatsQuery);) {
      stmt.setLong(1, flightId);
      stmt.setInt(2, count);
      ResultSet rs = stmt.executeQuery();
      while (rs.next()) {
        seats.add(rs.getLong(1));
      }
    }

    return seats;
  }

  private long createBooking(OracleConnection conn) throws SQLException {
    final String createBookingDML = "INSERT INTO bookings (created_at) VALUES (NULL) RETURNING ID INTO ?";
    try (OraclePreparedStatement stmt = (OraclePreparedStatement) conn.prepareStatement(createBookingDML)) {
      stmt.registerReturnParameter(1, java.sql.Types.NUMERIC);
      stmt.execute();
      ResultSet rs = stmt.getReturnResultSet();

      rs.next();
      return rs.getLong(1);
    }
  }


  private List<CheckoutResponseDTO.TicketDTO> getTickets(OracleConnection conn, long bookingId) throws SQLException {
    final String ticketsQuery = """
        SELECT t1.seat_id, t2.flight_id, t3.price
        FROM tickets t1
             JOIN seats t2 ON t1.seat_id = t2.id
             JOIN flights t3 ON t2.flight_id = t3.id
        WHERE t1.booking_id = ?
    """;
    List<CheckoutResponseDTO.TicketDTO> tickets = new ArrayList<>();

    try (PreparedStatement stmt = conn.prepareStatement(ticketsQuery)) {
      stmt.setLong(1, bookingId);
      ResultSet rs = stmt.executeQuery();
      while (rs.next()) {
        tickets.add(new CheckoutResponseDTO.TicketDTO(rs.getLong(1), rs.getLong(2), rs.getFloat(3)));
      }
    }

    return tickets;
  }
}
