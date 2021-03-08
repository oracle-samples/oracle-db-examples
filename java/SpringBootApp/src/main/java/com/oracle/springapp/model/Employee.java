package com.oracle.springapp.model;

import java.sql.Date;
import java.sql.Timestamp;
/**
 * Simple model for EMP table.
 *
 */
public class Employee {
	private Integer empno;
	private String name;
	private String job;
	private Integer manager;
	private Date hiredate;
	private Integer salary;
	private Integer commission;
	private Integer deptno;
	
	public Employee(int _empno,
			String _name,
			String _job,
			int _mgr,
			Date date,
			int _sal,
			int _commission,
			int _deptno) {
		empno = _empno;
		name = _name;
		job = _job;
		manager = _mgr;
		hiredate = date;
		salary = _sal;
		commission = _commission;
		deptno = _deptno;
	}


	public Integer getEmpno() {
		return empno;
	}

	public void setEmpno(int empno) {
		this.empno = empno;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getJob() {
		return job;
	}

	public void setJob(String job) {
		this.job = job;
	}

	public Integer getManager() {
		return manager;
	}

	public void setManager(int mgr) {
		this.manager = mgr;
	}

	public Integer getSalary() {
		return salary;
	}

	public void setSalary(int sal) {
		this.salary = sal;
	}

	public Integer getDeptno() {
		return deptno;
	}
	
	public Integer getCommission() {
		return commission;
		
	}
	
	public Date getHiredate() {
		return hiredate;
	}
	
	public void setHiredate(Timestamp hiredate) {
		this.setHiredate(hiredate);
	}
	
	public void setCommission(int commission) {
		this.commission=commission;
		
	}

	public void setDeptno(int deptno) {
		this.deptno = deptno;
	}

	public String toString() {
		return String.format("%20s %20s %20s %20s %20s %20s %20s %20s", empno, name,
				job, manager, hiredate, salary, commission, deptno);

	}
}
