import java.util.List;

import javax.sql.DataSource;

import org.springframework.jdbc.core.JdbcTemplate;

/**
 * Simple Java class which uses Spring's JdbcTemplate class to implement
 * business logic.
 *
 */
public class EmpJDBCTemplate {
	private DataSource dataSource;
	private JdbcTemplate jdbcTemplate;

	public void setDataSource(DataSource dataSource) {
		this.dataSource = dataSource;
		this.jdbcTemplate = new JdbcTemplate(dataSource);

	}

	public void displayEmpList() {
		final String sql = "SELECT empno, ename, job, mgr, sal, deptno FROM emp";
		List<EmployeeDAO> employees = jdbcTemplate.query(sql, new EmployeeMapper());

		System.out.println(
				String.format("%20s %20s %20s %20s %20s %20s \n", "EMPNO", "ENAME", "JOB", "MGR", "SALARY", "DEPT"));
		

		for (EmployeeDAO employee : employees) {
			System.out.println(String.format("%20d %20s %20s %20d %20d %20d", employee.getEmpno(), employee.getName(),
					employee.getJob(), employee.getMgr(), employee.getSal(), employee.getDeptno()));
		}
	}
}
