package com.oracle.springapp.dao;

import java.util.List;

import com.oracle.springapp.model.AllTables;

/**
 * Simple DAO interface for EMP table.
 *
 */
public interface AllTablesDAO {
	public List<AllTables> getTableNames();
}

