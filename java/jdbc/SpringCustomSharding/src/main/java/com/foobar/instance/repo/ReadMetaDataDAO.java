/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.instance.repo;

import com.foobar.instance.domain.MetaData;
import oracle.jdbc.internal.OracleConnection;
import oracle.ucp.jdbc.PoolDataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.support.JdbcDaoSupport;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Simple Java class which uses Spring's JdbcDaoSupport class to implement
 * business logic.
 * select host_name, VERSION_FULL,INSTANCE_NAME, (select open_mode from v$database) open_mode from v$instance;
 */
@Repository
@Transactional(readOnly = true, transactionManager = "readTransactionManager")
public class ReadMetaDataDAO extends JdbcDaoSupport {

    ReadMetaDataDAO(@Qualifier("readDataSource") DataSource readDataSource)
    {
        super();
        this.setDataSource(readDataSource);
    }

    public MetaData getInstance(String country) {
        final String sql = "select host_name, version_full, instance_name, " +
                "(select open_mode from v$database) open_mode, " +
                " SYS_CONTEXT('USERENV', 'SERVICE_NAME') service_name " +
                "from v$instance";
        MetaData retval = getJdbcTemplate().queryForObject(sql,
                (rs, rowNum) -> new MetaData(
                        rs.getString("host_name"),
                        rs.getString("version_full"),
                        rs.getString("instance_name"),
                        rs.getString("open_mode"),
                        rs.getString("service_name")
                ));

        try {
            if(false) {
                // ONS troubleshooting
                DataSource datasource = this.getDataSource();
                PoolDataSource pd = (PoolDataSource) this.getDataSource();
                Connection conn = datasource.getConnection();
                Properties into = ((OracleConnection) conn).getServerSessionInfo();
                conn.close();
                String ons = pd.getONSConfiguration();
                }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }

        return retval;
    }
}
