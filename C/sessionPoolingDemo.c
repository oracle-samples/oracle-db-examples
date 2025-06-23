/* Copyright (c) 2025, Oracle and/or its affiliates.*/
/*
   NAME
     sessionPoolingDemo.c - Basic OCI Session Pooling with multithreading
   DESCRIPTION
     This program invokes multiple threads to insert MAXTHREADS records
     into the EMPLOYEES table using session pools (Employee ids 100-109).
     This program assumes that sample HR schema is setup and the EMPLOYEES
     table is created with employee_id as the primary key.
*/

#ifndef OCI_ORACLE
# include <oci.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAXTHREADS 10 // Maximum number of threads

// Maximum lengths for columns
#define MAX_NAME_LEN_FIRST 20
#define MAX_NAME_LEN_LAST  25
#define MAX_EMAIL_LEN      50
#define MAX_JOB_LEN        20

static ub4 sessMin = 3; // Min no. of pooled sessions
static ub4 sessMax = 8; // Max no. of pooled sessions
static ub4 sessIncr = 5; // increment number

static OCIError *errhp;
static OCIEnv   *envhp;
static OCISPool *poolhp = (OCISPool *) 0;
static int employeeNum[MAXTHREADS];

static OraText *poolName;
static ub4 poolNameLen;

// application user to set the database credentials here
static char *username = "<username>";
static char *password = "<password>";
static char *connstr = "<connect string>";

/*  Values to be inserted into the 'employees' table */
static char* firstname[10] = { "A","B","C","D","E","F","G","H","I","J" };
static char* lastname[10] = { "A","B","C","D","E","F","G","H","I","J"} ;
static char* email[10] = { "A@example.com","B@example.com","C@example.com",
                           "D@example.com","E@example.com","F@example.com",
                           "G@example.com","H@example.com","I@example.com",
                           "J@example.com"};
static char* ejob[10] = { "FI_ACCOUNT","AC_ACCOUNT","SA_MAN","PU_MAN",
                          "PU_CLERK","IT_PROG","MK_REP","AD_VP","AC_MGR",
                          "HR_REP" };
static float esal[10] = { 10000.00, 5000.00,
                          8000.00, 6000.00,
                          10000.00, 8000.50,
                          6000.00, 6000.70,
                          5000.00, 5000.00 };

static char* hiredate[10] = { "07-JUN-96", "08-JAN-95", "18-JUL-98",
                              "21-FEB-99", "02-JUL-04", "13-AUG-08",
                              "28-DEC-10", "27-SEP-15", "01-JUL-16",
                              "01-AUG-19" };

static unsigned int edept_id[10] = { 10, 20, 10, 20, 30, 10, 30, 20, 10, 20 };

static void checkerr (OCIError *errhp, sword status);
static void threadFunction (dvoid *arg);
static void fetchAndPrintData(void);
static sword threadCleanup(OCISvcCtx *svchp, OCIAuthInfo *authInfop,
  OCIError* errhp1, OCIStmt *stmthp);

/* ----------------------------------------------------------------- */
/*  Main function definition                                         */
/* ----------------------------------------------------------------- */
int main(void)
{
  int timeout = 1; // 1 second
  sword status;
  int i = 0;

  /** Stage 1: Establish connection to the database using session pool */

  // set the environment handle to use OCI threaded mode
  OCIEnvCreate(&envhp, OCI_THREADED, (dvoid *) 0,  NULL, NULL, NULL, 0,
                (dvoid *) 0);

  // Allocate the error and pool handles
  (void) OCIHandleAlloc((dvoid *) envhp, (dvoid **) &errhp, OCI_HTYPE_ERROR,
                        (size_t) 0, (dvoid **) 0);
  (void) OCIHandleAlloc((dvoid *) envhp, (dvoid **) &poolhp, OCI_HTYPE_SPOOL,
                        (size_t) 0, (dvoid **) 0);

  // set the session pool timeout
  checkerr(errhp, OCIAttrSet((dvoid *) poolhp,
                  (ub4) OCI_HTYPE_SPOOL, (dvoid *) &timeout, (ub4) 0,
                  OCI_ATTR_SPOOL_TIMEOUT, errhp));

  // session pool creation
  if (status = OCISessionPoolCreate(envhp, errhp, poolhp,
              (OraText **) &poolName, (ub4 *) &poolNameLen,
              (const OraText *) connstr,
              (ub4)strlen((const signed char *) connstr),
              sessMin, sessMax, sessIncr, (OraText *) username,
              (ub4)strlen((const signed char *) username),
              (OraText *) password,
              (ub4)strlen((const signed char *) password),
              OCI_DEFAULT))
    checkerr(errhp,status);

  printf("Session Pool: \"%s\" Created \n", poolName);

  /** Stage 2: Insert employee data using OCI Session Pools and Threads */

  OCIThreadId *thrid[MAXTHREADS];
  OCIThreadHandle *thrhp[MAXTHREADS];

  OCIThreadProcessInit();
  checkerr (errhp, OCIThreadInit(envhp, errhp));
  for (i = 0; i < MAXTHREADS; ++i)
  {
    checkerr(errhp, OCIThreadIdInit(envhp, errhp, &thrid[i]));
    checkerr(errhp, OCIThreadHndInit(envhp, errhp, &thrhp[i]));
  }
  for (i = 0; i < MAXTHREADS; ++i)
  {
    employeeNum[i] = i;
    // Create the threads for inserting the records into the
    // "employee" table
    checkerr(errhp, OCIThreadCreate(envhp, errhp, threadFunction,
                    (dvoid *) &employeeNum[i], thrid[i], thrhp[i]));
  }
  for (i = 0; i < MAXTHREADS; ++i)
  {
    checkerr(errhp, OCIThreadJoin(envhp, errhp, thrhp[i]));
    checkerr(errhp, OCIThreadClose(envhp, errhp, thrhp[i]));
    checkerr(errhp, OCIThreadIdDestroy(envhp, errhp, &(thrid[i])));
    checkerr(errhp, OCIThreadHndDestroy(envhp, errhp, &(thrhp[i])));
  }
  checkerr(errhp, OCIThreadTerm(envhp, errhp));

  /** Stage 3: Fetch the inserted data and print it */

  // fetch and print the entire employee data inserted
  (void) fetchAndPrintData();

  /** Stage 4: Close the session pool and clean up buffers and handles */

  // Close the session pool
  status =  OCISessionPoolDestroy(poolhp, errhp, OCI_DEFAULT);
  if (status != OCI_SUCCESS)
    checkerr(errhp, status);
  printf("Session Pool: \"%s\" Closed.\n", poolName);

  // free all handles and buffers
  checkerr(errhp, OCIHandleFree((dvoid *) poolhp, OCI_HTYPE_SPOOL));
  checkerr(errhp, OCIHandleFree((dvoid *) errhp, OCI_HTYPE_ERROR));
  if (envhp)
    OCIHandleFree((dvoid *) envhp, (ub4) OCI_HTYPE_ENV);

  OCITerminate(OCI_DEFAULT);
  return 0;
}

/* ----------------------------------------------------------------- */
/*  Inserts records into the 'employees' table                       */
/* ----------------------------------------------------------------- */
static void threadFunction(dvoid *arg)
{
  int idx = *(int *)arg;
  int empno = idx + 100;
  int firstnm_len = strlen((char *) firstname[idx]) + 1;
  int lastnm_len = strlen((char *) lastname[idx]) + 1;
  int em_len = strlen((char *) email[idx]) + 1;
  int job_len = strlen((char *) ejob[idx]) + 1;
  OraText firstnm[firstnm_len],
          lastnm[lastnm_len],
          em[em_len],
          job[job_len];

  // OCI handle and pointer declarations
  OCISvcCtx *svchp = (OCISvcCtx *) 0;
  OCIStmt *stmthp = (OCIStmt *) 0;
  OCIError  *errhp2 = (OCIError *) 0; // separate error handle for the thread
  OCIAuthInfo *authp = (OCIAuthInfo *) 0;
  OCIBind *bndp_arr[8] = {
    (OCIBind *) 0, (OCIBind *) 0, (OCIBind *) 0, (OCIBind *) 0,
    (OCIBind *) 0, (OCIBind *) 0, (OCIBind *) 0, (OCIBind *) 0
  };
  OCIDefine *defnp = (OCIDefine *) 0;

  // SQL statements to execute
  OraText *insertstmt = (OraText *) "INSERT INTO EMPLOYEES(employee_id,\
                  first_name, last_name, email, hire_date, job_id, salary,\
                  department_id) values(:empid, :firstname, :lastname,\
                  :email, :hiredt, :ejob, :esal, :edept_id)";

  sword status;

  // allocate error handle and session authentication information handle
  (void) OCIHandleAlloc((dvoid *) envhp, (dvoid **) &errhp2, OCI_HTYPE_ERROR,
                     (size_t) 0, (dvoid **) 0);
  checkerr(errhp2, OCIHandleAlloc((dvoid *) envhp,
                    (dvoid **) &authp, (ub4) OCI_HTYPE_AUTHINFO,
                    (size_t) 0, (dvoid **) 0));

  // set user credentials into the authentication informaton handle
  checkerr(errhp2, OCIAttrSet((dvoid *) authp,(ub4) OCI_HTYPE_AUTHINFO,
                    (dvoid *) username, (ub4) strlen((char *) username),
                    (ub4) OCI_ATTR_USERNAME, errhp2));
  checkerr(errhp2,OCIAttrSet((dvoid *) authp,(ub4) OCI_HTYPE_AUTHINFO,
                    (dvoid *) password, (ub4) strlen((char *) password),
                    (ub4) OCI_ATTR_PASSWORD, errhp2));

  // get a session from the pool
  checkerr(errhp2, OCISessionGet(envhp, errhp2, &svchp, authp,
                    (OraText *) poolName, (ub4) strlen((char *) poolName),
                    NULL, 0, NULL, NULL, NULL, OCI_SESSGET_SPOOL));

  // prepare the INSERT statement
  checkerr(errhp2, OCIStmtPrepare2(svchp, (OCIStmt **) &stmthp, errhp2,
                    (const OraText *) insertstmt,
                    (ub4)strlen((const signed char *) insertstmt),
                    NULL, 0, OCI_NTV_SYNTAX, OCI_DEFAULT));

  // bind the placeholders in the INSERT statement
  if ((status = OCIBindByName(stmthp, &bndp_arr[0], errhp2,
              (OraText *) ":EMPID", -1, (dvoid *) &empno,
              (sword) sizeof(empno), SQLT_INT, (dvoid *) 0,
              (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT)) ||
      (status = OCIBindByName(stmthp, &bndp_arr[1], errhp2,
              (OraText *) ":FIRSTNAME", -1, (dvoid *) firstname[idx],
              firstnm_len, SQLT_STR, (dvoid *) 0,
              (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT)) ||
      (status = OCIBindByName(stmthp, &bndp_arr[2], errhp2,
              (OraText *) ":LASTNAME", -1, (dvoid *) lastname[idx],
              lastnm_len, SQLT_STR, (dvoid *) 0,
              (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT)) ||
      (status = OCIBindByName(stmthp, &bndp_arr[3], errhp2,
              (OraText *) ":EMAIL", -1, (dvoid *) email[idx],
              em_len, SQLT_STR, (dvoid *) 0,
              (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT)) ||
      (status = OCIBindByName(stmthp, &bndp_arr[4], errhp2,
              (OraText *) ":HIREDT", -1, (dvoid *) hiredate[idx],
              strlen((char *) hiredate[idx]) + 1, SQLT_STR, (dvoid *) 0,
              (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT)) ||
      (status = OCIBindByName(stmthp, &bndp_arr[5], errhp2,
              (OraText *) ":EJOB", -1, (dvoid *) ejob[idx],
              job_len, SQLT_STR, (dvoid *) 0,
              (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT)) ||
      (status = OCIBindByName(stmthp, &bndp_arr[6], errhp2,
              (OraText *) ":ESAL", -1, (dvoid *) &esal[idx],
              (sword) sizeof(esal[idx]), SQLT_FLT, (dvoid *) 0,
              (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT)) ||
      (status = OCIBindByName(stmthp, &bndp_arr[7], errhp2,
             (OraText *) ":EDEPT_ID",
             -1, (dvoid *) &edept_id[idx],
             (sword) sizeof(edept_id[idx]), SQLT_INT, (dvoid *) 0,
             (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT)))
  {
    checkerr(errhp2, status);
    threadCleanup(svchp, authp, errhp2, stmthp);
    return; // exit from the thread function
  }

  // execute and commit the INSERT statement
  status = OCIStmtExecute(svchp, stmthp, errhp2, (ub4) 1, (ub4) 0,
            (OCISnapshot *) 0, (OCISnapshot *) 0, OCI_DEFAULT);
  if (status != OCI_SUCCESS) {
    // INSERT failed!
    printf("INSERT failed for employee id: %d\n", empno);
    checkerr(errhp2, status);
    threadCleanup(svchp, authp, errhp2, stmthp);
    return; // exit from the thread function
  }

  // commit the transaction
  checkerr(errhp2, OCITransCommit(svchp, errhp2 ,(ub4) 0));

  printf("Employee id %d added.\n", empno);

  // cleanup the handles
  threadCleanup(svchp, authp, errhp2, stmthp);
}

/* ----------------------------------------------------------------- */
/*  Fetch and print data from the 'employees' table                  */
/* ----------------------------------------------------------------- */
static void fetchAndPrintData(void)
{
  OraText firstnm[MAX_NAME_LEN_FIRST];
  OraText lastnm[MAX_NAME_LEN_LAST];
  OraText email[MAX_EMAIL_LEN];
  OraText job[MAX_JOB_LEN];
  sword empno;

  // Indicator variables for NULL values (0 for not NULL, -1 for NULL)
  sb2 firstnm_ind = 0; // Indicator variable for firstnm
  sb2 lastnm_ind = 0;  // Indicator variable for lastnm
  sb2 email_ind = 0;   // Indicator variable for email
  sb2 job_ind = 0;     // Indicator variable for job

  // OCI handle and pointer declarations
  OCISvcCtx *svchp = (OCISvcCtx *) 0;
  OCIStmt *stmthp = (OCIStmt *) 0;
  OCIError  *errhp2 = (OCIError *) 0; // separate error handle for the thread
  OCIAuthInfo *authp = (OCIAuthInfo *) 0;
  OCIDefine *defnp = (OCIDefine *) 0;

  sword status;

  // SQL statements to execute
  OraText *selectstmt = (OraText *) "SELECT employee_id, first_name, last_name,\
                                      email, job_id FROM EMPLOYEES";

  // allocate error handle and session authentication information handle
  (void) OCIHandleAlloc((dvoid *) envhp, (dvoid **) &errhp2, OCI_HTYPE_ERROR,
                     (size_t) 0, (dvoid **) 0);
  checkerr(errhp2, OCIHandleAlloc((dvoid *) envhp,
                    (dvoid **) &authp, (ub4) OCI_HTYPE_AUTHINFO,
                    (size_t) 0, (dvoid **) 0));

  // set user credentials into the authentication informaton handle
  checkerr(errhp2, OCIAttrSet((dvoid *) authp,(ub4) OCI_HTYPE_AUTHINFO,
                    (dvoid *) username, (ub4) strlen((char *) username),
                    (ub4) OCI_ATTR_USERNAME, errhp2));
  checkerr(errhp2,OCIAttrSet((dvoid *) authp,(ub4) OCI_HTYPE_AUTHINFO,
                    (dvoid *) password, (ub4) strlen((char *) password),
                    (ub4) OCI_ATTR_PASSWORD, errhp2));

  // get a session from the pool
  checkerr(errhp2, OCISessionGet(envhp, errhp2, &svchp, authp,
                    (OraText *) poolName, (ub4) strlen((char *) poolName),
                    NULL, 0, NULL, NULL, NULL, OCI_SESSGET_SPOOL));

  // prepare the SELECT statement
  checkerr(errhp2, OCIStmtPrepare2(svchp, (OCIStmt **) &stmthp, errhp2,
                    (const OraText *) selectstmt,
                    (ub4)strlen((const signed char *) selectstmt),
                    NULL, 0, OCI_NTV_SYNTAX, OCI_DEFAULT));

  // allocate and define output buffers for the SELECT statement
  if (status = OCIDefineByPos(stmthp, &defnp, errhp, 1,
                (dvoid *) &empno, (sb4) sizeof(empno), SQLT_INT,
                (dvoid *) &firstnm_ind, (ub2 *) 0, (ub2 *) 0, OCI_DEFAULT))
  {
    checkerr(errhp, status);
    threadCleanup(svchp, authp, errhp2, stmthp);
    return;
  }
  if (status = OCIDefineByPos(stmthp, &defnp, errhp, 2,
                (dvoid *) firstnm, (sb4) sizeof(firstnm), SQLT_STR,
                (dvoid *) &firstnm_ind, (ub2 *) 0, (ub2 *) 0, OCI_DEFAULT))
  {
    checkerr(errhp, status);
    threadCleanup(svchp, authp, errhp2, stmthp);
    return;
  }
  if (status = OCIDefineByPos(stmthp, &defnp, errhp, 3,
                (dvoid *) lastnm, (sb4) sizeof(lastnm), SQLT_STR,
                (dvoid *) &lastnm_ind, (ub2 *) 0, (ub2 *) 0, OCI_DEFAULT))
  {
    checkerr(errhp, status);
    threadCleanup(svchp, authp, errhp2, stmthp);
    return;
  }
  if (status = OCIDefineByPos(stmthp, &defnp, errhp, 4,
                            (dvoid *) email, (sb4) sizeof(email), SQLT_STR,
                            (dvoid *) &email_ind, (ub2 *) 0, (ub2 *) 0, OCI_DEFAULT))
  {
    checkerr(errhp, status);
    threadCleanup(svchp, authp, errhp2, stmthp);
    return;
  }
  if (status = OCIDefineByPos(stmthp, &defnp, errhp, 5,
                             (dvoid *) job, (sb4) sizeof(job), SQLT_STR,
                             (dvoid *) &job_ind, (ub2 *) 0, (ub2 *) 0, OCI_DEFAULT))
  {
    checkerr(errhp, status);
    threadCleanup(svchp, authp, errhp2, stmthp);
    return;
  }

  // Execute the SELECT statement
  // set the 4th parameter (iters) of OCIStmtExecute to 0 as we do not know
  // the number of rows that will be fetched
  checkerr(errhp2, OCIStmtExecute(svchp, stmthp, errhp2, (ub4) 0, (ub4) 0,
            (OCISnapshot *) 0, (OCISnapshot *) 0, OCI_DEFAULT));

  printf("\nEmployee Details:\n");
  printf("---------------------------------------------------------------------------------------------------------------------------------\n");
  printf("%-15s %-25s %-25s %-50s %-20s\n","EMPLOYEE ID", "FIRST NAME", "LAST NAME", "EMAIL", "JOB");
  printf("---------------------------------------------------------------------------------------------------------------------------------\n");

    // Loop until OCI_NO_DATA is returned, indicating no more rows.
    while ((status = OCIStmtFetch2(stmthp, errhp, (ub4) 1, OCI_FETCH_NEXT,
      (sb4) 0, OCI_DEFAULT)) != OCI_NO_DATA) {
        checkerr(errhp, status);

        // Check indicator variables for NULL values and handle them
        if (firstnm_ind == -1) {
            strcpy(firstnm, "NULL");
        }
        if (lastnm_ind == -1) {
            strcpy(lastnm, "NULL");
        }
        if (email_ind == -1) {
            strcpy(email, "NULL");
        }
        if (job_ind == -1) {
            strcpy(job, "NULL");
        }

        printf("%-15d %-25s %-25s %-50s %-20s\n", empno, firstnm, lastnm, email, job);
    }
    printf("-------------------------------------------------------------------------------------------------------------------------------\n");

  // cleanup the handles
  threadCleanup(svchp, authp, errhp2, stmthp);
}

/* ----------------------------------------------------------------- */
/*  Checks for errors and displays them                              */
/* ----------------------------------------------------------------- */
void checkerr(OCIError *errhp, sword status)
{
  OraText errbuf[512];
  sb4 errcode = 0;

  switch (status)
  {
  case OCI_SUCCESS:
    break;
  case OCI_SUCCESS_WITH_INFO:
    (void) printf("Error - OCI_SUCCESS_WITH_INFO\n");
    break;
  case OCI_NEED_DATA:
    (void) printf("Error - OCI_NEED_DATA\n");
    break;
  case OCI_NO_DATA:
    (void) printf("Error - OCI_NODATA\n");
    break;
  case OCI_ERROR:
    (void) OCIErrorGet((dvoid *)errhp, (ub4) 1, (OraText *) NULL, &errcode,
                       errbuf, (ub4) sizeof(errbuf), OCI_HTYPE_ERROR);
    (void) printf("Error - %.*s\n", 512, errbuf);
    break;
  case OCI_INVALID_HANDLE:
    (void) printf("Error - OCI_INVALID_HANDLE\n");
    break;
  case OCI_STILL_EXECUTING:
    (void) printf("Error - OCI_STILL_EXECUTE\n");
    break;
  case OCI_CONTINUE:
    (void) printf("Error - OCI_CONTINUE\n");
    break;
  default:
    break;
  }
}

/*---------------------------------------------------------------------*/
/* Close thread and clean up                                           */
/*---------------------------------------------------------------------*/
sword threadCleanup(OCISvcCtx *svchp, OCIAuthInfo *authInfop,
  OCIError *errhp1, OCIStmt *stmthp)
{
  checkerr(errhp1, OCIStmtRelease(stmthp, errhp1, (OraText *) NULL, (ub4) 0,
                                (ub4) OCI_DEFAULT));
  checkerr(errhp1, OCISessionRelease(svchp, errhp1, NULL, 0, OCI_DEFAULT));
  OCIHandleFree((dvoid *) authInfop, OCI_HTYPE_AUTHINFO);
  OCIHandleFree((dvoid *) errhp1, OCI_HTYPE_ERROR);
  return OCI_SUCCESS;
}
