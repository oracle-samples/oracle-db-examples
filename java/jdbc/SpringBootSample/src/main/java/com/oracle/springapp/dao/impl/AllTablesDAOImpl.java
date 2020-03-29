package com.oracle.springapp.dao.impl;

import java.util.List;

import javax.annotation.PostConstruct;
import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.support.JdbcDaoSupport;
import org.springframework.stereotype.Repository;

import com.oracle.springapp.dao.AllTablesDAO;
import com.oracle.springapp.model.AllTables;
/**
 * Simple Java class which uses Spring's JdbcDaoSupport class to implement
 * business logic.
 *
 */
@Repository
public class AllTablesDAOImpl extends JdbcDaoSupport implements AllTablesDAO {
	@Autowired
	private DataSource dataSource;

	@PostConstruct
	public void initialize() {
		setDataSource(dataSource);
		System.out.println("Datasource used: " + dataSource);
	}

	@Override
	public List<AllTables> getTableNames() {
		final String sql = "SELECT owner, table_name, status, num_rows FROM all_tables where rownum < 20";
		return getJdbcTemplate().query(sql, 
				(rs, rowNum) -> new AllTables(rs.getString("owner"),
						rs.getString("table_name"),
						rs.getString("status"),
						rs.getInt("num_rows")			
						));	
		
	}
}


