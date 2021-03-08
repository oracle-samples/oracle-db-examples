package com.oracle.springapp.service;

import com.oracle.springapp.model.Employee;

public interface EmployeeService {
	/**
	 * Display all employees.
	 */
	public void displayEmployees();
	
	/**
	 * Get table name of the top 20 tables
	 */
	
	public void displayTableNames();
	
	/**
	 * Create a new employee record
	 */
	
	public void insertEmployee(Employee employee);

	
}
