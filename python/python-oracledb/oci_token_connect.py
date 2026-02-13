# -----------------------------------------------------------------------------
# Copyright (c) 2023, 2024 Oracle and/or its affiliates.
#
# This software is dual-licensed to you under the Universal Permissive License
# (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl and Apache License
# 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
# either license.
#
# If you elect to accept the software under the Apache License, Version 2.0,
# the following applies:
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# oci_token_connect.py
#
# Demonstrates how to connect from ADB from EC2 instance using IAM Token
#
# Prepare:
# - Enable external IAM Authentication
#   exec DBMS_CLOUD_ADMIN.ENABLE_EXTERNAL_AUTHENTICATION(type => 'OCI_IAM',force => TRUE );
#   SELECT NAME, VALUE FROM V$PARAMETER WHERE NAME='identity_provider_type';
#
# - Create database user
#   CREATE USER db_token_user IDENTIFIED GLOBALLY AS 'IAM_GROUP_NAME=oci_free';
#   GRANT CONNECT, RESOURCE, SELECT_CATALOG_ROLE to db_token_user;
#
# - Create dynamic group oci_free (Enter here OCID of your Compute Instance)
#   Any {instance.id = 'ocid1.instance.oc1.eu-frankfurt-1....' }
# 
# - Create policy oci_free_policy (1s rule grants connection, 2nd rule grants connect string)
#   allow dynamic-group oci_free to use database-connections in tenancy
#   allow dynamic-group oci_free to inspect autonomous-database-family in tenancy
#
# -----------------------------------------------------------------------------

adb_ocid = 'ocid1.autonomousdatabase.oc1.eu-frankfurt-1.antheljrubxjciiamwditmuq3nykeywqgne6j76u4cm3flacguyp63c532ya'

import logging
import sys
import os
import oracledb
import jwt
import requests
from datetime import datetime, timedelta, timezone
import oci

from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
from oci.identity_data_plane import DataplaneClient
from oci.identity_data_plane.models import GenerateScopedAccessTokenDetails

# Setup logging
stream_handler = logging.StreamHandler(sys.stderr)
logging.basicConfig(handlers=[stream_handler], level=logging.DEBUG, force=True)

# This class represent callback which generates IAM token
class TokenHandlerIAM:
    # Class static variables
    token_expiry = datetime.now(timezone.utc) - timedelta(minutes=1)
    scoped_token = None
    private_key_pem = None
    public_key_pem = None

    def __init__(self, compartment_ocid, config, signer):
        self.compartment_ocid = compartment_ocid
        self.config = config
        self.signer = signer
        self.scope = f"urn:oracle:db::id::{compartment_ocid}"
        logging.debug(f'IAM token for: {self.scope}')

    def __call__(self, refresh):
        if TokenHandlerIAM.token_expiry > datetime.now(timezone.utc) - timedelta(minutes=1):
            logging.debug('Returning cached token')
            return (TokenHandlerIAM.scoped_token, TokenHandlerIAM.private_key_pem)

        logging.debug('Refreshing cached token')

        # 2. Initialize DataplaneClient with instance principal
        logging.debug(f'Getting db client')
        client = DataplaneClient(config=self.config, signer=self.signer)
        # Generate a new private key
        logging.debug(f'Generating private key')
        private_key = rsa.generate_private_key(
            public_exponent=65537,   # Standard value for RSA
            key_size=4096            # 2048 bits is a secure default
        )

        private_key_pem = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        ).decode("utf-8")
        if not oracledb.is_thin_mode():
            p_key = "".join(
                line.strip()
                for line in private_key_pem.splitlines()
                if not (
                        line.startswith("-----BEGIN") or line.startswith("-----END")
                )
            )
            private_key_pem = p_key

        public_key_pem = (
            private_key.public_key()
            .public_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PublicFormat.SubjectPublicKeyInfo,
            )
            .decode("utf-8")
        )

        # 4. Prepare token request payload
        logging.debug(f'Token details')
        token_details = GenerateScopedAccessTokenDetails(scope=self.scope,
                                                         public_key=public_key_pem)
        # 5. Generate scoped token
        logging.debug(f'Response')
        response = client.generate_scoped_access_token(token_details)
        # Get token from response
        logging.debug(f'Scoped access token')
        scoped_token = response.data.token

        payload = jwt.decode(scoped_token, options={"verify_signature": False})
        token_expiry = payload['exp']  # Token expiry as a Unix timestamp

        logging.debug(f'Scoped_token: {str(scoped_token)}')
        logging.debug(f'Token expiry: {datetime.fromtimestamp(token_expiry, timezone.utc).isoformat()}')
        TokenHandlerIAM.scoped_token = scoped_token
        TokenHandlerIAM.private_key_pem = private_key_pem
        TokenHandlerIAM.public_key_pem = public_key_pem
        TokenHandlerIAM.token_expiry = datetime.fromtimestamp(token_expiry, timezone.utc)
        return scoped_token, private_key_pem


def is_running_on_compute_instance():
    """
    Detect if this code is running on an OCI Compute instance via IMDSv2 metadata endpoint.
    """
    try:
        response = requests.get(
            "http://169.254.169.254/opc/v2/instance/",
            headers={"Authorization": "Bearer Oracle"},
            timeout=5
        )
        return response.status_code == 200
    except Exception as e:
        logging.debug(str(e))
        return False


def get_signer():
    """
    Return the OCI signer , either from Resource principal, Instance Principals or Security Token
    Signer class is used to sign your requests for IAM
    :return: Signer instance
    """
    logging.info(f'Getting signer')
    config = {}

    # Detect OKE Kubernetes cluster
    # This works only on Enhanced Clusters
    # if 'KUBERNETES_SERVICE_HOST' in os.environ or os.path.exists('/var/run/secrets/kubernetes.io/serviceaccount/token'):
    #     logging.info(f'Oracle Kubernetes Service Host')
    #     return oci.auth.signers.get_oke_workload_identity_resource_principal_signer(), config

    if 'KUBERNETES_SERVICE_HOST' in os.environ or os.path.exists('/var/run/secrets/kubernetes.io/serviceaccount/token'):
        logging.info(f'Oracle Kubernetes Service Host')
        return oci.auth.signers.InstancePrincipalsSecurityTokenSigner(), config

    # Detect OCI Function
    if "OCI_RESOURCE_PRINCIPAL_VERSION" in os.environ or 'OCI_FN_APPLICATION_ID' in os.environ or 'FN_APP_ID' in os.environ:
        logging.info(f'Getting signer using resource principals')
        return oci.auth.signers.get_resource_principals_signer(), config

    # Check whether we're running on users laptop
    if os.path.isfile(os.path.expanduser("~/.oci/config")):
        logging.info(f'Getting signer using user session token')
        # Fallback to Token-based Authentication for the CLI/Python SDK
        # https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/clitoken.htm#Running_Scripts_on_a_Computer_without_a_Browser
        config = oci.config.from_file(file_location="~/.oci/config", profile_name="DEFAULT")
        token_file = config['security_token_file']
        with open(token_file, 'r') as f:
            token = f.read()
        private_key = oci.signer.load_private_key_from_file(config['key_file'])
        signer = oci.auth.signers.SecurityTokenSigner(token, private_key)
        return signer, config

    # Detect Compute instance (one way, not foolproof)
    if is_running_on_compute_instance():
        logging.info(f'Getting signer using instance principals')
        return oci.auth.signers.InstancePrincipalsSecurityTokenSigner(), config

    logging.error(f'Error getting signer instance')
    raise RuntimeError(f'Error getting signer instance')
    

signer, config = get_signer()        
db_client = oci.database.DatabaseClient(config=config, signer=signer)

# Loop over Databases profiles and find low priority connection string
compartment_ocid = db_client.get_autonomous_database(adb_ocid).data.compartment_id
for profile in db_client.get_autonomous_database(adb_ocid).data.connection_strings.profiles:
    if profile.consumer_group == 'LOW':
        dsn = profile.value
        # Fixup: since 23ai 'YES' is not allowed
        dsn = dsn.replace('ssl_server_dn_match=yes', 'ssl_server_dn_match=true') 
        break
else:
    logging.error(f'Failed to get OCI DB profile LOW')
    raise ValueError(f'Failed to get OCI DB profile LOW')
logging.info(f'dsn found: {dsn}')

# Initialize database client in Thick mode
try:
    if oracledb.is_thin_mode():
        ORACLE_HOME = os.environ['ORACLE_HOME']
        TNS_ADMIN = os.environ['TNS_ADMIN']        
        logging.debug(f'Executing db.init_oracle_client() with lib_dir={ORACLE_HOME}')
        oracledb.init_oracle_client(lib_dir=ORACLE_HOME)
except Exception as w:
    logging.debug(f'Executing db.init_oracle_client()')
    oracledb.init_oracle_client()

logging.info(f'Connecting using IAM Token')
try:
    connection = oracledb.connect(
        access_token=TokenHandlerIAM(compartment_ocid, config, signer),
        externalauth=True,  # must always be True in Thick mode
        dsn=dsn
    )
except oracledb.DatabaseError as fc:
    err, = fc.args
    logging.error(f'Leaving get_connection w/{err.message}')
    raise RuntimeError(f'Failed to connect to database: {dsn} with error message {err.message}')
    
with connection.cursor() as cursor:
    sql = """
    SELECT USER, \
    SYS_CONTEXT('USERENV', 'CURRENT_USER')           CURRENT_USER, \
    SYS_CONTEXT('USERENV', 'AUTHENTICATED_IDENTITY') AUTHENTICATED_IDENTITY, \
    SYS_CONTEXT('USERENV', 'ENTERPRISE_IDENTITY')    ENTERPRISE_IDENTITY, \
    SYS_CONTEXT('USERENV', 'IDENTIFICATION_TYPE')    IDENTIFICATION_TYPE
    FROM sys.dual \
    """

    cursor.execute(sql)
    result = cursor.fetchone()
    logging.info(f'Authenticated as: {str(result)}')
