package rsi.example.common;

import oracle.rsi.StreamEntity;
import oracle.rsi.StreamField;
import oracle.sql.json.OracleJsonObject;
import oracle.sql.json.OracleJsonValue;

import java.util.stream.Stream;

@StreamEntity(tableName = "retailer")
public class Retailer {

  public Retailer(OracleJsonObject jsonObject) {
    Stream
        .of(this.getClass().getDeclaredFields())
        .filter(df -> (df.getAnnotation(StreamField.class) != null))
        .forEach(f -> {
          f.setAccessible(true);

          String fieldName = f.getName();
          OracleJsonValue jsonValue = jsonObject.get(fieldName);
          OracleJsonValue.OracleJsonType type = jsonValue.getOracleJsonType();

          try {
            switch (type) {
            case DECIMAL:
              f.setInt(this, jsonValue.asJsonDecimal().intValue());
              break;
            case STRING:
              f.set(this, jsonValue.asJsonString().getString());
              break;
            default:
              throw new IllegalArgumentException("unknown type");
            }
          } catch (IllegalAccessException ex) {
            ex.printStackTrace();
          }
        });
  }

  @StreamField
  public int rank;

  @StreamField
  public int msr;

  @StreamField
  public String retailer;

  @StreamField
  public String name;

  @StreamField
  public String city;

  @StreamField
  public String phone;

  @StreamField
  public String terminal_type;

  @StreamField
  public int weeks_active;

  @StreamField
  public String instant_sales_amt;

  @StreamField
  public String online_sales_amt;

  @StreamField
  public String total_sales_amt;

}
