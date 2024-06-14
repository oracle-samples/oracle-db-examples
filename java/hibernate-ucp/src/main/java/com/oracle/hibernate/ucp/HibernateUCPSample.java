package com.oracle.hibernate.ucp;

import org.hibernate.HibernateException;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.boot.Metadata;
import org.hibernate.boot.MetadataSources;
import org.hibernate.boot.registry.StandardServiceRegistry;
import org.hibernate.boot.registry.StandardServiceRegistryBuilder;
import org.hibernate.jdbc.Work;

import java.sql.Connection;
import java.sql.SQLException;

public class HibernateUCPSample {

  public static void main( String[] args ) throws HibernateException {
    StandardServiceRegistry ssr = new StandardServiceRegistryBuilder().build();
    Metadata meta = new MetadataSources(ssr).getMetadataBuilder().build();

    SessionFactory factory = meta.getSessionFactoryBuilder().build();
    Session session = factory.openSession();

    session.doWork(new Work() {
      public void execute(Connection con) throws SQLException {
        // Prints the UCP proxy class, indicating that UCP is configured as a datasource
	System.out.println("Connection class: " + con.getClass());
      }
    });

    factory.close();
    session.close();
  }
}
