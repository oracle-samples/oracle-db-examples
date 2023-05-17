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
*/

package com.oracle.jdbc.dev.rsi;

import oracle.rsi.StreamEntity;
import oracle.rsi.StreamField;

@StreamEntity(tableName = "customers")
public class Customer {

  public Customer(long id, String name, String region) {
    super();
    this.id = id;
    this.name = name;
    this.region = region;
  }

  @StreamField
  public long id;

  @StreamField
  public String name;

  @StreamField(columnName = "region")
  public String region;

  String someRandomField;

}