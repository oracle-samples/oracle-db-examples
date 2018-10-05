import java.sql.ResultSet;
import java.sql.SQLException;

import org.springframework.jdbc.core.RowMapper;

/**
 * Simple Row mapper implementation class for EMP table.
 *
 */
public class EmployeeMapper implements RowMapper<EmployeeDAO> {

	@Override
	public EmployeeDAO mapRow(ResultSet rs, int rowNo) throws SQLException {
		EmployeeDAO emp = new EmployeeDAO();
		emp.setName(rs.getString("ename"));
		return emp;
	}

}
