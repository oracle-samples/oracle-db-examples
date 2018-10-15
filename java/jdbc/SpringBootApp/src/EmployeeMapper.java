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
		emp.setEmpno(rs.getInt("empno"));
		emp.setName(rs.getString("ename"));
		emp.setJob(rs.getString("job"));
		emp.setMgr(rs.getInt("mgr"));
		emp.setSal(rs.getInt("sal"));
		emp.setDeptno(rs.getInt("deptno"));

		return emp;
	}

}
