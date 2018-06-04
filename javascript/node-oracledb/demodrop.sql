/* Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved. */

/******************************************************************************
 *
 * You may not use the identified files except in compliance with the Apache
 * License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * NAME
 *   demodrop.sql
 *
 * DESCRIPTION
 *   Drop example database objects created in demo.sql
 *
 *****************************************************************************/

SET ECHO ON

DROP PROCEDURE testproc;

DROP FUNCTION testfunc;

DROP PROCEDURE get_emp_rs;

DROP PACKAGE beachpkg;

DROP TABLE j_purchaseorder;

DROP TABLE j_purchaseorder_b;

DROP TABLE dmlrupdtab;

DROP TABLE mylobs;

DROP TYPE dorow;

DROP FUNCTION mydofetch;

DROP TABLE myraw;

DROP TABLE waveheight;

DROP PROCEDURE lob_in_out;

DROP PROCEDURE lobs_in;

DROP PROCEDURE lobs_out;

DROP TABLE em_tab;

DROP TABLE em_childtab;

DROP TABLE em_parenttab;

DROP PROCEDURE em_testproc;

DROP TABLE cqntable;
