package com.oracle.springapp.dao;

import java.util.List;

import com.oracle.springapp.model.Employee;

/**
 * Simple DAO interface for EMP table.
 *
 */
public interface EmployeeDAO {
	public List<Employee> getAllEmployees();

	void insertEmployee(Employee employee);
}
