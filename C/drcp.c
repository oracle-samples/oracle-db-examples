/* Copyright (c) 2022, Oracle. All rights reserved. */

/* drcp.c */

/* Oracle OCI Database Resident Connection Pooling (DRCP) Example */
/* Christopher Jones, 2014 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <oci.h>

// const OraText userName[] = "SCOTT";
// const OraText userPassword[] = "TIGER";

/* Take the user credentials as inputs*/
OraText userName[129];
OraText userPassword[129];
const OraText connectString[] = "localhost/orclpdb:pooled"; /* Request a "pooled" connection with the correct DB service name */
const OraText connectionClassName[] = "MYTEST";                                        /* DRCP connection class name */

#define DRCP_PURITY OCI_ATTR_PURITY_SELF /* Reuse DB sessions for maximum pooling benefit */
#define NUM_ITERS 10                     /* Default number of times to get a server from the DB pool and do a query */
#define THINK_TIME 3                     /* Default seconds to sleep between loop iterations */

static void do_query(OCISvcCtx *svchp, OCIError *errhp);
static void checkerr(OCIError *errhp, sword status);

int main(int argc, char **argv)
{
    OCIEnv *envhp = NULL;
    OCIError *errhp = NULL;
    OCIAuthInfo *authInfop = NULL;
    OCISvcCtx *svchp = NULL;
    OraText *poolName = NULL;
    ub4 poolNameLen = 0;
    OCISPool *spoolhp = NULL;
    ub4 purity;
    int rc;
    int i;
    int numIters = NUM_ITERS;
    int thinkTime = THINK_TIME;
    text errbuf[OCI_ERROR_MAXMSG_SIZE];
    sb4 oracode;

    /*
     * Set the loop count and think time between iterations
     */

        if (argc == 3)
        {
            numIters = atoi(argv[1]);
            thinkTime = atoi(argv[2]);
        }
        else if (argc != 1)
        {
            printf("Usage: %s [loop_count think_time]\n", argv[0]);
            exit(1);
        }
        printf("Iterating %d times with %d second sleep between iterations\n\n", numIters, thinkTime);

    /*
     * Initialize the DB context
     */

    rc = OCIEnvNlsCreate(&envhp, OCI_DEFAULT, 0, NULL, NULL, NULL, 0, NULL, 0, 0);
    if (rc != OCI_SUCCESS)
    {
        oracode = 0;
        *errbuf = '\0';
        if (envhp)
            OCIErrorGet(envhp, 1, NULL, &oracode, errbuf, sizeof(errbuf), OCI_HTYPE_ENV);
        if (*errbuf)
            printf("OCIEnvNlsCreate failed: %d : %s\n", oracode, errbuf);
        else
            printf("OCIEnvNlsCreate returned status: %d\n", rc);
        exit(1);
    }

    rc = OCIHandleAlloc(envhp, (void **)&errhp, OCI_HTYPE_ERROR, 0, NULL);
    if (rc != OCI_SUCCESS)
    {
        oracode = 0;
        *errbuf = '\0';
        OCIErrorGet(envhp, 1, NULL, &oracode, errbuf, sizeof(errbuf), OCI_HTYPE_ENV);
        if (*errbuf)
            printf("OCIHandleAlloc failed: %d : %s\n", oracode, errbuf);
        else
            printf("OCIHandleAlloc returned status: %d\n", rc);
        exit(1);
    }

    rc = OCIHandleAlloc(envhp, (void **)&authInfop, OCI_HTYPE_AUTHINFO, 0, NULL);
    checkerr(errhp, rc);

    rc = OCIHandleAlloc(envhp, (void **)&spoolhp, OCI_HTYPE_SPOOL, 0, NULL);
    checkerr(errhp, rc);

    printf("Enter the DB username: ");
    scanf("%s", userName);
    printf("Enter the DB password: ");
    scanf("%s", userPassword);

    rc = OCISessionPoolCreate(envhp, errhp, spoolhp, &poolName, &poolNameLen,
                              connectString, strlen((char *)connectString), 0, UB4MAXVAL, 1,
                              (OraText *)userName, strlen((char *)userName),
                              (OraText *)userPassword, strlen((char *)userPassword),
                              OCI_SPC_NO_RLB | OCI_SPC_HOMOGENEOUS);
    checkerr(errhp, rc);
    if (rc != OCI_SUCCESS && rc != OCI_SUCCESS_WITH_INFO)
        exit(1);
    /*
     * Set the connection class name and purity.  These could be set
     * inside the loop before OCISessionGet() if the values vary
     * between loop iterations, for example if the loop is controlling
     * multiple, different kinds of work.
     */

    rc = OCIAttrSet(authInfop, OCI_HTYPE_AUTHINFO,
                    (void *)connectionClassName, strlen((char *)connectionClassName),
                    OCI_ATTR_CONNECTION_CLASS, errhp);
    checkerr(errhp, rc);
    
    /* Uncomment the 4 lines below to set the Purity attribute of the pool to new */
    // purity = DRCP_PURITY;
    // purity = OCI_ATTR_PURITY_NEW;
    // rc = OCIAttrSet(authInfop, OCI_HTYPE_AUTHINFO, (dvoid *)&purity, 0, OCI_ATTR_PURITY, errhp);
    // checkerr(errhp, rc);

    /*
     * Loop, alternately doing DB operations and non-DB operations aka
     * sleeping (in this example)
     */

    for (i = 0; i < numIters; ++i)
    {
    /*
     * Simulate doing non-DB work between iterations
     */

        if (i > 0)
            {
                printf("\nSleeping %d seconds...\n\n", thinkTime);
                sleep(thinkTime);
            }
    
    /*
     * Get a DRCP pooled server. The associated service handle is
     * returned from OCISessionGet and then used for DB
     * operations.  After use here, the DRCP pooled server is
     * released back to the DB pool for reuse by other
     * applications.
     */
    rc = OCISessionGet(envhp, errhp, &svchp, authInfop, poolName, poolNameLen,
                       NULL, 0, NULL, NULL, NULL, OCI_SESSGET_SPOOL);
    checkerr(errhp, rc);
    if (rc != OCI_SUCCESS && rc != OCI_SUCCESS_WITH_INFO)
        exit(1);
    printf("The user tables available are: \n");
    do_query(svchp, errhp);
    rc = OCISessionRelease(svchp, errhp, NULL, 0, OCI_DEFAULT);
    checkerr(errhp, rc);
    if (rc != OCI_SUCCESS && rc != OCI_SUCCESS_WITH_INFO)
        exit(1);
    }

    checkerr(errhp, OCISessionPoolDestroy(spoolhp, errhp, OCI_DEFAULT));
    checkerr(errhp, OCIHandleFree((dvoid *)spoolhp, OCI_HTYPE_SPOOL));
    checkerr(errhp, OCIHandleFree((dvoid *)authInfop, OCI_HTYPE_AUTHINFO));
    OCIHandleFree((dvoid *)errhp, OCI_HTYPE_ERROR);
    OCIHandleFree((dvoid *)envhp, OCI_HTYPE_ENV);

    exit(0);
}

/*
 * Query a single column varchar column
 */

const OraText queryString[] =
    "SELECT table_name FROM user_tables WHERE ROWNUM < 21 ORDER BY table_name";
#define COLUMN_LENGTH (128 + 1)
#define ARRAY_SIZE 100 /* Number of rows to array fetch */

static void do_query(OCISvcCtx *svchp, OCIError *errhp)
{
    OCIStmt *stmtp = NULL;
    OCIDefine *defnpp = NULL;
    int rc;
    int i;
    int num_rows_fetched = 0;
    char column_data[ARRAY_SIZE][COLUMN_LENGTH];

    rc = OCIStmtPrepare2(svchp, &stmtp, errhp, queryString, strlen((char *)queryString),
                         NULL, 0, OCI_NTV_SYNTAX, OCI_DEFAULT);
    checkerr(errhp, rc);
    rc = OCIDefineByPos(stmtp, &defnpp, errhp, 1, (void *)column_data, COLUMN_LENGTH,
                        SQLT_STR, NULL, NULL, NULL, OCI_DEFAULT);
    checkerr(errhp, rc);
    rc = OCIStmtExecute(svchp, stmtp, errhp, ARRAY_SIZE, 0, NULL, NULL, OCI_DEFAULT); /* execute & fetch ARRAY_SIZE rows */
    if (rc != OCI_NO_DATA)                                                            /* OCI_NO_DATA is expected at EOF */
        checkerr(errhp, rc);

    while (rc == OCI_SUCCESS || rc == OCI_NO_DATA)
    {
        OCIAttrGet(stmtp, OCI_HTYPE_STMT, (void *)&num_rows_fetched, NULL, OCI_ATTR_ROWS_FETCHED, errhp);

        for (i = 0; i < num_rows_fetched; ++i)
            printf("%s\n", column_data[i]);

        if (rc == OCI_NO_DATA)
            break;

        rc = OCIStmtFetch2(stmtp, errhp, ARRAY_SIZE, OCI_DEFAULT, 0, OCI_DEFAULT);
        if (rc != OCI_NO_DATA) /* OCI_NO_DATA is expected at EOF */
            checkerr(errhp, rc);
    }

    rc = OCIStmtRelease(stmtp, errhp, NULL, 0, OCI_DEFAULT);
    checkerr(errhp, rc);
}

/*
 * Check Errors
 */

void checkerr(errhp, status)
    OCIError *errhp;
sword status;
{
    OraText errbuf[OCI_ERROR_MAXMSG_SIZE];
    sb4 errcode = 0;
    switch (status)
    {
    case OCI_SUCCESS:
        break;
    case OCI_SUCCESS_WITH_INFO:
        printf("Error - OCI_SUCCESS_WITH_INFO\n");
        break;
    case OCI_NEED_DATA:
        printf("Error - OCI_NEED_DATA\n");
        break;
    case OCI_NO_DATA:
        printf("Error - OCI_NO_DATA\n");
        break;
    case OCI_ERROR:
        OCIErrorGet((void *)errhp, 1, (OraText *)NULL, &errcode, errbuf, sizeof(errbuf), OCI_HTYPE_ERROR);
        printf("Error - %.*s\n", (int)sizeof(errbuf), errbuf);
        break;
    case OCI_INVALID_HANDLE:
        printf("Error - OCI_INVALID_HANDLE\n");
        break;
    case OCI_STILL_EXECUTING:
        printf("Error - OCI_STILL_EXECUTE\n");
        break;
    case OCI_CONTINUE:
        printf("Error - OCI_CONTINUE\n");
        break;
    default:
        break;
    }
}
