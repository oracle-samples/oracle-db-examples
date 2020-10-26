package lod.networkbuffer;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import oracle.spatial.network.lod.NetworkAnalyst;
import oracle.spatial.network.lod.LODNetworkManager;
import oracle.spatial.network.lod.LinkCostCalculator;
import oracle.spatial.network.lod.NetworkIO;
import oracle.spatial.network.lod.PointOnNet;
import oracle.spatial.network.lod.util.PrintUtility;
import oracle.spatial.util.Logger;
import oracle.spatial.network.lod.NetworkBuffer;
import oracle.spatial.network.lod.NodeCostCalculator;
import oracle.spatial.network.lod.config.ConfigManager;
import oracle.spatial.network.lod.config.LODConfig;

public class PersistentNetworkBuffer
{
  private static final NumberFormat formatter = new DecimalFormat("#.######");
  
  private static NetworkAnalyst analyst;
  private static NetworkIO networkIO;
  
  private static void setLogLevel(String logLevel)
  {
    if("FATAL".equalsIgnoreCase(logLevel))
        Logger.setGlobalLevel(Logger.LEVEL_FATAL);
    else if("ERROR".equalsIgnoreCase(logLevel))
        Logger.setGlobalLevel(Logger.LEVEL_ERROR);
    else if("WARN".equalsIgnoreCase(logLevel))
        Logger.setGlobalLevel(Logger.LEVEL_WARN);
    else if("INFO".equalsIgnoreCase(logLevel))
        Logger.setGlobalLevel(Logger.LEVEL_INFO);
    else if("DEBUG".equalsIgnoreCase(logLevel))
        Logger.setGlobalLevel(Logger.LEVEL_DEBUG);
    else if("FINEST".equalsIgnoreCase(logLevel))
        Logger.setGlobalLevel(Logger.LEVEL_FINEST);
    else  //default: set to ERROR
        Logger.setGlobalLevel(Logger.LEVEL_ERROR);
  }
  
    private static boolean tableExists(Connection conn, String tableName) 
    {
       boolean result = false;
       try {
             Statement stmt = conn.createStatement();
             String sqlStr = "SELECT COUNT(*) FROM TAB WHERE TNAME = '" + tableName.toUpperCase() + "'";
             ResultSet rs   = stmt.executeQuery(sqlStr); 
          
             if ( rs.next() ) {
                int no = rs.getInt(1);
             if ( no != 0 )
                result = true; 
             }
            rs.close();   
            stmt.close();
        }
        catch (Exception e) {
            e.printStackTrace();
        }   
        return result;
    }  

public static void main(String[] args) throws Exception
  {

    System.out.println("\n\ncreate reaching buffer\n\n");

    String configXmlFile = "lod/networkbuffer/LODConfigs.xml";
    String logLevel    =   "ERROR";
        
    String dbUrl       = ""; // jdbc url
    String dbUser      = "";
    String dbPassword  = "";

    String networkName = "HERE_SF_NET";

    long startNodeId       = 48523065;
    long linkId            = 947224640;
    double percent         = 0;

    long[] linkIds = {915260080, 711576509, -23618421, -127806843, 23618590, 23595880, 23594646, 23748128, 23611433, -127806839, 23612874, -916623909};
    double[] percents = {0.2, 0.48, 0.27, 0.72, 0.63, 0.14, 0.1, 1, 0.29, 0.14, 0, 0};


    int linkLevel          = 1;          //default link level
    // double cost            = 10*1600;    // 10 miles converted to meters
    double cost            = 10*60;    // 10 minutes converted to seconds
    String tableNamePrefix = "SF";

    Connection conn    = null;
    
    //get input parameters
      for(int i=0; i<args.length; i++)
      {
        if(args[i].equalsIgnoreCase("-dbUrl"))
          dbUrl = args[i+1];
        else if(args[i].equalsIgnoreCase("-dbUser"))
          dbUser = args[i+1];
        else if(args[i].equalsIgnoreCase("-dbPassword"))
          dbPassword = args[i+1];
        else if(args[i].equalsIgnoreCase("-networkName") && args[i+1]!=null)
          networkName = args[i+1].toUpperCase();
        else if(args[i].equalsIgnoreCase("-linkLevel"))
          linkLevel = Integer.parseInt(args[i+1]);
        else if(args[i].equalsIgnoreCase("-startNodeId"))
          startNodeId = Long.parseLong(args[i+1]);
        else if(args[i].equalsIgnoreCase("-cost:"))
          cost = Double.parseDouble(args[i]);
        else if(args[i].equalsIgnoreCase("-tableNamePrefix"))
          tableNamePrefix = args[i+1];
        else if(args[i].equalsIgnoreCase("-configXmlFile"))
          configXmlFile = args[i+1];
        else if(args[i].equalsIgnoreCase("-logLevel"))
          logLevel = args[i+1];
      }

      // opening connection
      conn = LODNetworkManager.getConnection(dbUrl, dbUser, dbPassword);

      Statement stmt = conn.createStatement();
    
      System.out.println("Network analysis for "+networkName);

      setLogLevel(logLevel);
    
      //load user specified LOD configuration (optional), 
      //otherwise default configuration will be used
      InputStream config = ClassLoader.getSystemResourceAsStream(configXmlFile);
      LODNetworkManager.getConfigManager().loadConfig(config);
      LODConfig c = LODNetworkManager.getConfigManager().getConfig(networkName);
      //get network input/output object
      networkIO = LODNetworkManager.getCachedNetworkIO(
                                    conn, networkName, networkName, null);
    
      //get network analyst
      analyst = LODNetworkManager.getNetworkAnalyst(networkIO);
      LinkCostCalculator[] oldlccs = analyst.getLinkCostCalculators();
      LinkCostCalculator[] lccs = {new LinkTravelTimeCalculator()};
      try
      {


        analyst.setLinkCostCalculators(lccs); 

        
        for (int i = 0; i < linkIds.length; i++) {
          int bufferId = i + 1;
          System.out.println("***** BEGIN: Network Buffer " + bufferId + " *****");

          linkId = linkIds[i];
          percent = percents[i];
          
          PointOnNet[] startPoint = {new PointOnNet(linkId, percent)};
          long startTime = System.currentTimeMillis();
          NetworkBuffer buffer = analyst.reachingNetworkBuffer(startPoint, cost, null);
          long t1 = System.currentTimeMillis();
          networkIO.writeNetworkBuffer(buffer, bufferId, tableNamePrefix);


          long endTime = System.currentTimeMillis();

          System.out.println("Run times : "+" Total = "+(endTime-startTime) +" msec."+
                         " Analysis = "+(t1-startTime)+" msec."+" Persistence = "+
                         (endTime-t1)+" msec.");
          System.out.println("***** END: Network Buffer" + bufferId + " *****");       
        }



      }
      catch (Exception e)
      {
        e.printStackTrace();
      }


    if(conn!=null)
      try{conn.close();} catch(Exception ignore){}

  }
}
