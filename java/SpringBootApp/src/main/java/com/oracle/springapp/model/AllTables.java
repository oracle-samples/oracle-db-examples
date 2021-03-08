package com.oracle.springapp.model;

/**
 *  Simple model for ALL_TABLES
 */
public class AllTables {
	private String owner;
	private String table_name;
	private String status;
	private int num_rows;

	
	public AllTables(String _owner,
			String _table_name,
			String _status,
			int _num_rows) {
		owner = _owner;
		table_name = _table_name;
		status = _status;
		num_rows = _num_rows;
	}


	public String getOwner() {
		return owner;
	}

	public String getTableName() {
		return table_name;
	}

	public String getStatus() {
		return status;
	}

	public int getNumRows() {
		return num_rows;
	}

	public String toString() {
		return String.format("%25s %25s %25s %20d", owner, table_name,
				status, num_rows);

	}

}
