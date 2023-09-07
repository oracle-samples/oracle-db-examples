/*
  Copyright (c) 2021, 2022, Oracle and/or its affiliates.
  This software is dual-licensed to you under the Universal Permissive License
  (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
  2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
  either license.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
     https://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/package rsi.example.common;

import oracle.rsi.StreamEntity;
import oracle.rsi.StreamField;
import oracle.sql.json.OracleJsonObject;
import oracle.sql.json.OracleJsonValue;

import java.util.stream.Stream;

/**
 * A POJO that defines the record to be streamed.
 * The class that is annotated with @StreamEntity means that its instances can be
 * stored in a database. Every instance of an entity represents a row in the table.
 * Fields that are annotated with @StreamField will be mapped to the corresponding
 * columns in the table.
 */
@StreamEntity(tableName = "retailer")
public class Retailer {

  /**
   * @param jsonObject jsonObject which is converted from the JSON payload
   */
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
