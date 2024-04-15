package com.oracle.hibernate.ucp;

import org.hibernate.HibernateException;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.boot.Metadata;
import org.hibernate.boot.MetadataSources;
import org.hibernate.boot.registry.StandardServiceRegistry;
import org.hibernate.boot.registry.StandardServiceRegistryBuilder;
import org.hibernate.cfg.Configuration;
import org.hibernate.jdbc.Work;

import oracle.ucp.UniversalConnectionPool;
import oracle.ucp.admin.UniversalConnectionPoolManager;
import oracle.ucp.admin.UniversalConnectionPoolManagerImpl;

import java.sql.Connection;
import java.sql.SQLException;

public class HibernateUCPSample {

  public static void main( String[] args ) throws HibernateException {
  	Configuration configuration = new Configuration();
    configuration.configure("hibernate.cfg.xml");
    StandardServiceRegistry ssr = new StandardServiceRegistryBuilder().applySettings(configuration.getProperties()).build();
    Metadata meta = new MetadataSources(ssr).getMetadataBuilder().build();

    SessionFactory factory = meta.getSessionFactoryBuilder().build();
    Session session = factory.openSession();

    try{
    	UniversalConnectionPoolManager mgr = UniversalConnectionPoolManagerImpl.getUniversalConnectionPoolManager();
    	UniversalConnectionPool pool = mgr.getConnectionPool("testucppool");
    	System.out.println(pool.getName());
    	System.out.println(pool.getAvailableConnectionsCount());
    }
    catch(Exception e) {
    	e.printStackTrace();
    }
    
    session.doWork(new Work() {
      public void execute(Connection con) throws SQLException {
        System.out.println("Connection class: " + con.getClass());
      }
    });

    factory.close();
    session.close();
  }
}