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
		final String sql = "SELECT ename FROM emp";
		List<EmployeeDAO> employees = jdbcTemplate.query(sql, new EmployeeMapper());
		for (EmployeeDAO employee : employees) {
			System.out.println(employee.getName());
		}
	}

}
