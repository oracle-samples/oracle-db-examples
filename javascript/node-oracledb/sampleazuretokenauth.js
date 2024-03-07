/* Copyright (c) 2023, Oracle and/or its affiliates. */

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
 *   sampleazuretokenauth.js
 *
 * DESCRIPTION
 *   This script shows connection pooling with token based authentication to
 *   Oracle Autonomous Database from @azure/msal-node SDK. It shows
 *   how to create a connection pool.
 *
 *   For more information refer to
 *   https://node-oracledb.readthedocs.io/en/latest/user_guide/
 *   connection_handling.html#oauth-2-0-token-based-authentication
 *
 * PREREQUISITES
 *   - node-oracledb 6.3 or later.
 *
 *   - While using Thick mode,
 *     Oracle Client libraries 19.15 (or later), or 21.7 (or later).
 *
 *   - Package @azure/msal-node.
 *     See, https://www.npmjs.com/package/@azure/msal-node
 *
 *   - Set these environment variables (see the code explanation):
 *     NODE_ORACLEDB_CLIENTID, NODE_ORACLEDB_SCOPES,
 *     NODE_ORACLEDB_AUTHORITY, NODE_ORACLEDB_CLIENTSECRET,
 *     NODE_ORACLEDB_CONNECTIONSTRING, NODE_ORACLEDB_AUTHTYPE,
 *     NODE_ORACLEDB_DRIVER_MODE, NODE_ORACLEDB_CLIENT_LIB_DIR
 *
********************************************************************************/
const msal = require('@azure/msal-node');
const oracledb = require('oracledb');
let accessTokenData;

// This example runs in both node-oracledb Thin and Thick modes.
//
// Optionally run in node-oracledb Thick mode
if (process.env.NODE_ORACLEDB_DRIVER_MODE === 'thick') {

  // Thick mode requires Oracle Client or Oracle Instant Client libraries.
  // On Windows and macOS Intel you can specify the directory containing the
  // libraries at runtime or before Node.js starts.  On other platforms (where
  // Oracle libraries are available) the system library search path must always
  // include the Oracle library path before Node.js starts.  If the search path
  // is not correct, you will get a DPI-1047 error.  See the node-oracledb
  // installation documentation.
  let clientOpts = {};
  // On Windows and macOS Intel platforms, set the environment
  // variable NODE_ORACLEDB_CLIENT_LIB_DIR to the Oracle Client library path
  if (process.platform === 'win32' ||
      (process.platform === 'darwin' && process.arch === 'x64')) {
    clientOpts = { libDir: process.env.NODE_ORACLEDB_CLIENT_LIB_DIR };
  }
  oracledb.initOracleClient(clientOpts);  // enable node-oracledb Thick mode
}

console.log(oracledb.thin ? 'Running in thin mode' : 'Running in thick mode');

//---------------------------------------------------------------------------
// Returns access token for authentication as a service principal. This
// authentication method requires a client ID along with either a secret or
// certificate. These values may be provided as config parameters,
// read by the Azure SDK.
//---------------------------------------------------------------------------
async function servicePrincipalCredentials(params) {
  const tokenRequest = {
    scopes: [params.scopes],
  };

  const msalConfig = {
    auth: {
      clientId: params.clientId,
      authority: params.authority,
      clientSecret: params.clientSecret,
    },
    system: {
      networkClient: params.networkClient,
      proxyUrl: params.proxyUrl,
    }
  };
  const cca = new msal.ConfidentialClientApplication(msalConfig);
  const authResponse = await cca.acquireTokenByClientCredential(tokenRequest);
  return authResponse.accessToken;
}

//---------------------------------------------------------------------------
// Returns access token for a username and password.
// msalConfig having parameters required for token generation
// using username and password
//---------------------------------------------------------------------------
async function passwordCredentials(params) {
  const msalConfig = {
    auth: {
      clientId: params.clientId,
      authority: params.authority,
      clientSecret: params.clientSecret,
    },
    system: {
      networkClient: params.networkClient,
      proxyUrl: params.proxyUrl,
    }
  };

  const cca = new msal.ConfidentialClientApplication(msalConfig);
  const usernamePasswordRequest = {
    scopes: [params.scopes],
    userName: params.userName,
    password: params.password,
  };
  const authResponse =
    await cca.acquireTokenByUsernamePassword(usernamePasswordRequest);
  return authResponse.accessToken;
}

// User defined function for reading token value generated by Azure SDK
async function getToken(accessTokenConfig) {
  switch (accessTokenConfig.authType) {
    case 'servicePrincipal':
      return await servicePrincipalCredentials(accessTokenConfig);
    case 'password':
      return await passwordCredentials(accessTokenConfig);
    default:
      throw new Error(`Unrecognized authentication-method: ${accessTokenConfig.authType}`);
  }
}

// user defined callback function
async function callbackfn(refresh, accessTokenConfig) {
  // When refresh is true, then the token is invalid or expired.
  //  So the application must get a new token and store it in cache.
  // When refresh is false, then the token is valid and not expired
  // but the cache is empty. So the application must get a new token
  // and store it in cache.
  if (refresh || !accessTokenData) {
    accessTokenData = await getToken(accessTokenConfig);
  }

  // return token from cache
  return accessTokenData;
}

async function run() {
  // Configuration for token based authentication:
  //   accessToken:         The initial token values
  //   externalAuth:        Must be set to true for token based authentication
  //   homogeneous:         Must be set to true for token based authentication
  //   connectString:       The NODE_ORACLEDB_CONNECTIONSTRING environment
  //                        variable set to the Oracle Net alias or connect
  //                        descriptor of your Oracle Autonomous Database
  //    accessTokenConfig:  Parameter values needed for token generation through
  //                        OCI SDK.
  //  Configuration for accessTokenConfig:
  //    clientId:           Must be set to app id of Azure's application
  //    authority:          Must be set to a string, in URI format with tenant
  //                        https://{identity provider instance}/{tenantId}
  //                        Common authority URLs:
  //                        https://login.microsoftonline.com/<tenant>/
  //                        https://login.microsoftonline.com/common/
  //                        https://login.microsoftonline.com/organizations/
  //                        https://login.microsoftonline.com/consumers/
  //    scopes:             Must be set https://{uri}/clientID/.default for client
  //                        credential flows
  //    clientSecret:       Can be set only when authType property is set to
  //                        servicePrincipal. clientSecret is a string that
  //                        the Azure's application uses to prove its identity
  //                        when requesting a token.
  //    authType:           Must be set to servicePrincipal or password
  const config = {
    accessToken: callbackfn,
    accessTokenConfig: {
      clientId: process.env.NODE_ORACLEDB_CLIENTID,
      authority: process.env.NODE_ORACLEDB_AUTHORITY,
      scopes: process.env.NODE_ORACLEDB_SCOPES,
      clientSecret: process.env.NODE_ORACLEDB_CLIENTSECRET,
      authType: process.env.NODE_ORACLEDB_AUTHTYPE,
    },
    externalAuth: true,
    homogeneous: true,
    connectString: process.env.NODE_ORACLEDB_CONNECTIONSTRING,
  };

  try {

    // Create pool using token based authentication
    await oracledb.createPool(config);

    // A real app would call createConnection() multiple times over a long
    // period of time.  During this time the pool may grow.  If the initial
    // token has expired, node-oracledb will automatically call the
    // accessTokenCallback function allowing you to update the token.
    await createConnection();

  } catch (err) {
    console.error(err);
  } finally {
    await closePoolAndExit();
  }
}

async function createConnection() {
  // Get a connection from the default pool
  const connection = await oracledb.getConnection();
  try {
    const sql = `SELECT TO_CHAR(current_date, 'DD-Mon-YYYY HH24:MI') AS D
                 FROM DUAL`;
    const result = await connection.execute(sql);
    console.log("Result is:\n", result);
  } finally {
    await connection.close();
  }
}

async function closePoolAndExit() {
  console.log('\nTerminating');
  // Get the pool from the pool cache and close it
  await oracledb.getPool().close(0);
}

run();
