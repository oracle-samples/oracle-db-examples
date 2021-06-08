package com.oracle.springapp.service.impl;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.oracle.springapp.model.Employee;
import com.oracle.springapp.service.EmployeeService;
import com.oracle.springapp.dao.EmployeeDAO;

import com.oracle.springapp.model.AllTables;
import com.oracle.springapp.dao.AllTablesDAO;

@Service
public class EmployeeServiceImpl implements EmployeeService {

	@Autowired
	EmployeeDAO employeeDao;
	
	
	@Autowired
	AllTablesDAO allTablesDao;
	
	/**
	 *  Get the top 20 table names from all tables 
	 */
	@Override
	public void displayTableNames() {
		List<AllTables> allTables_list = allTablesDao.getTableNames();
		
		System.out.println(" Displaying Table Names ");

		System.out.println(String.format("%20s %20s %20s %20s \n", 
				"OWNER", "TABLE_NAME", "STATUS", "NUM_ROWS"));
		
		for(AllTables allTables: allTables_list)
			System.out.println(allTables);
	}
	
	/**
	 *  Displays the Employees from the EMP table 
	 */

	@Override
	public void displayEmployees() {
		List<Employee> employees = employeeDao.getAllEmployees();

		System.out.println(String.format("%20s %20s %20s %20s %20s %20s %20s %20s \n", 
				"EMPNO", "ENAME", "JOB", "MGR", "HIREDATE", "SALARY", "COMM", "DEPT"));
		
		for(Employee employee: employees)
			System.out.println(employee);
	}
	
	@Override
	public void insertEmployee(Employee employee) {
		employeeDao.insertEmployee(employee);	
	}
	
	
}
