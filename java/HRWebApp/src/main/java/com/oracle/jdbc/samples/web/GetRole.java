/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.oracle.jdbc.samples.web;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 *
 * @author nirmala.sundarappa@oracle.com
 */
@WebServlet(name = "GetRole", urlPatterns = {"/getrole"})
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
public class GetRole extends HttpServlet {

  private static final String[] ROLES = {"manager", "staff" };

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

    response.setContentType("text/css");
    String returnValue = "anonymous";
    for (String role : ROLES) {
      if(request.isUserInRole(role)) {
        returnValue = role;
        break;
      }
    }

    response.getWriter().print(returnValue);
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
