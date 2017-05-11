/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.oracle.jdbc.samples.web;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.oracle.jdbc.samples.bean.JdbcBean;
import com.oracle.jdbc.samples.bean.JdbcBeanImpl;
import com.oracle.jdbc.samples.entity.Employee;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;


/**
 *
 * @author nirmala.sundarappa@oracle.com
 */
@WebServlet(name = "WebController", urlPatterns = {"/WebController"})
/*
@ServletSecurity(
    httpMethodConstraints = {
        @HttpMethodConstraint(value = "GET", rolesAllowed = "staff"),
        @HttpMethodConstraint(value = "GET", rolesAllowed = "manager"),
        @HttpMethodConstraint(value = "POST", rolesAllowed = "manager",
            transportGuarantee = NONE),
    }
)
*/
public class WebController extends HttpServlet {

  private static final String INCREMENT_PCT = "incrementPct" ;
  private static final String ID_KEY = "id";
  private static final String FN_KEY = "firstName";
  private static final String LOGOUT = "logout";

  JdbcBean jdbcBean = new JdbcBeanImpl();

  private void reportError(HttpServletResponse response, String message)
      throws ServletException, IOException {
    response.setContentType("text/html;charset=UTF-8");

    try (PrintWriter out = response.getWriter()) {
      out.println("<!DOCTYPE html>");
      out.println("<html>");
      out.println("<head>");
      out.println("<title>Servlet WebController</title>");
      out.println("</head>");
      out.println("<body>");
      out.println("<h1>" + message + "</h1>");
      out.println("</body>");
      out.println("</html>");
    }
  }

  /**
   * Processes requests for both HTTP <code>GET</code> and <code>POST</code>
   * methods.
   *
   * @param request servlet request
   * @param response servlet response
   * @throws ServletException if a servlet-specific error occurs
   * @throws IOException if an I/O error occurs
   */
  protected void processRequest(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {
    Gson gson = new Gson();

    String value = null;
    List<Employee> employeeList = null;
    if ((value = request.getParameter(ID_KEY)) != null) {
      int empId = Integer.valueOf(value).intValue();
      employeeList = jdbcBean.getEmployee(empId);
    }
    else if ((value = request.getParameter(FN_KEY)) != null) {
      employeeList = jdbcBean.getEmployeeByFn(value);
    }
    else if ((value = request.getParameter(LOGOUT)) != null) {
      // faking logoff
      // response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
      // return;
      /* Getting session and then invalidating it */

      HttpSession session = request.getSession(false);
      if (request.isRequestedSessionIdValid() && session != null) {
        session.invalidate();
      }
      handleLogOutResponse(request,response);
      response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
    }
    else {
      employeeList = jdbcBean.getEmployees();
    }

    if(employeeList != null) {
      response.setContentType("application/json");
      gson.toJson(employeeList,
          new TypeToken<ArrayList<Employee>>() {
          }.getType(),
          response.getWriter());
    }
    else {
      response.setStatus(HttpServletResponse.SC_NOT_FOUND);
    }

  }


  /**
   * This method would edit the cookie information and make JSESSIONID empty
   * while responding to logout. This would further help in order to. This would help
   * to avoid same cookie ID each time a person logs in.
   * @param response
   * @param request
   */
  private void handleLogOutResponse(HttpServletRequest request, HttpServletResponse response) {
    Cookie[] cookies = request.getCookies();
    for (Cookie cookie : cookies) {
      cookie.setMaxAge(0);
      cookie.setValue(null);
      cookie.setPath("/");
      response.addCookie(cookie);

    }

  }

  // <editor-fold defaultstate="collapsed" desc="HttpServlet methods. Click on the + sign on the left to edit the code.">
  /**
   * Handles the HTTP <code>GET</code> method.
   *
   * @param request servlet request
   * @param response servlet response
   * @throws ServletException if a servlet-specific error occurs
   * @throws IOException if an I/O error occurs
   */
  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {
    processRequest(request, response);
  }

  /**
   * Handles the HTTP <code>POST</code> method.
   *
   * @param request servlet request
   * @param response servlet response
   * @throws ServletException if a servlet-specific error occurs
   * @throws IOException if an I/O error occurs
   */
  @Override
  protected void doPost(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {
    Map<String,String[]> x = request.getParameterMap();
    String value = null;
    if ((value = request.getParameter(INCREMENT_PCT)) != null) {
      Gson gson = new Gson();
      response.setContentType("application/json");
      List<Employee>  employeeList = jdbcBean.incrementSalary(Integer.valueOf(value));
      gson.toJson(employeeList,
          new TypeToken<ArrayList<Employee>>() {
          }.getType(),
          response.getWriter());
    }
    else {
      response.setStatus(HttpServletResponse.SC_NOT_FOUND);
    }
  }

  /**
   * Returns a short description of the servlet.
   *
   * @return a String containing servlet description
   */
  @Override
  public String getServletInfo() {
    return "JdbcWebServlet: Reading Employees table using JDBC and transforming it as a JSON.\n  Author: nirmala.sundarapp@oracle.com";
  }// </editor-fold>

}
