/* Copyright (c) 2025, Oracle and/or its affiliates.*/
/* All rights reserved.*/

/*
 *
 * NAME
 *  simpleConnDemo.c - Basic Oracle Call Interface (OCI) functionality
 *
 * DESCRIPTION
 *  An example program which adds new employee records to the personnel
 *  data base. Checking is done to validate the integrity of the data base.
 *  The employee numbers are automatically selected using the current
 *  maximum employee number as the start.
 *  For the required setup, see the blog:
 *  https://medium.com/oracledevs/oracle-call-interface-for-c-developers-simple-database-connection-and-query-58be8243a393
 *
 *  The program queries the user for data as follows:
 *
 *  Enter employee name:
 *  Enter employee job:
 *  Enter employee salary:
 *  Enter employee dept:
 *
 *  The program terminates if return key (Enter) is entered
 *  when the employee name is requested.
 *
 *  If the record is successfully inserted, the following
 *  is printed:
 *
 *  "ename" added to department "dname" as employee # "empno"
 *
 *  Demonstrates creating a connection, a session and executing some SQL.
 *  Also shows the usage of allocating memory for application use which has
 *  the life time of the handle.
 *
*/

#ifndef OCI_ORACLE
#include <oci.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Table specific constants
#define ENAME_MAXLEN 80
#define JOB_MAXLEN 50
#define DEPTNAME_MAXLEN 14

/* Define the SQL statements to be used in program. */
static OraText *insert = (OraText *) "INSERT INTO \
  emp(empno, ename, job, sal, deptno)\
  VALUES (:empno, :ename, :job, :sal, :deptno)";
static OraText *seldept = (OraText *) "SELECT dname FROM dept WHERE \
  deptno = :1";
static OraText *selmaxemp = (OraText *) "SELECT NVL(MAX(empno), 0) FROM emp";

static OCIEnv *envhp = NULL;
static OCIError *errhp = NULL;

static void checkerr(/*_ OCIError *errhp, sword status _*/);
static void myfflush(/*_ void _*/);
static void free_buffers(/*p_ename, p_job, p_dept*/);
static sword cleanup(/*svchp, authInfop, stmthp*/);

static sword status;
static boolean logged_on = FALSE;

/* ----------------------------------------------------------------- */
/*  Main function definition                                         */
/* ----------------------------------------------------------------- */
int main(int argc, char **argv)
{

  sword empno, deptno;
  float sal;
  sword len, len2;
  sb2 sal_ind, job_ind;
  OraText  *cp, *ename = NULL,
           *job = NULL, *dept = NULL;

  // application user to set the database credentials here
  char *username = "<username>";
  char *password = "<password>";
  char *connstr  = "<connect string>";

  OCIAuthInfo *authInfop = (OCIAuthInfo *) 0;
  OCISvcCtx *svchp = NULL;
  OCIStmt   *inserthp = NULL, // for the INSERT statement
            *stmthp = NULL; // for the SELECT statements
  OCIDefine *defnp = (OCIDefine *) 0;

  OCIBind  *bnd1p = (OCIBind *) 0,  /* the first bind handle */
           *bnd2p = (OCIBind *) 0,  /* the second bind handle */
           *bnd3p = (OCIBind *) 0,  /* the third bind handle */
           *bnd4p = (OCIBind *) 0,  /* the fourth bind handle */
           *bnd5p = (OCIBind *) 0,  /* the fifth bind handle */
           *bnd6p = (OCIBind *) 0;  /* the sixth bind handle */

  sword errcode = 0;

  /** Stage 1: Establish connection to the database */

  /* set the environment handle */
  errcode = OCIEnvCreate((OCIEnv **) &envhp, (ub4) OCI_DEFAULT,
                  (dvoid *) 0, (dvoid * (*)(dvoid *,size_t)) 0,
                  (dvoid * (*)(dvoid *, dvoid *, size_t)) 0,
                  (void (*)(dvoid *, dvoid *)) 0, (size_t) 0, (dvoid **) 0);

  if (errcode != 0) {
    (void) printf("OCIEnvCreate failed with errcode = %d.\n", errcode);
    exit(1);
  }

  /* allocate error and authentication information handles */
  (void) OCIHandleAlloc((dvoid *) envhp, (dvoid **) &errhp, OCI_HTYPE_ERROR,
                   (size_t) 0, (dvoid **) 0);
  (void) OCIHandleAlloc((dvoid *) envhp, (dvoid **) &authInfop,
                        (ub4) OCI_HTYPE_AUTHINFO, (size_t) 0, (dvoid **) 0);

  /* set user credentials on the authentication information handle */
  (void) OCIAttrSet((dvoid *) authInfop, (ub4) OCI_HTYPE_AUTHINFO,
                 (dvoid *) username, (ub4) strlen((char *)username),
                 (ub4) OCI_ATTR_USERNAME, errhp);
  (void) OCIAttrSet((dvoid *) authInfop, (ub4) OCI_HTYPE_AUTHINFO,
                 (dvoid *) password, (ub4) strlen((char *)password),
                 (ub4) OCI_ATTR_PASSWORD, errhp);

  /* connect to the database */
  status = OCISessionGet(envhp, errhp, &svchp, authInfop, (OraText *)connstr,
                      (ub4) strlen((char *)connstr), NULL, (ub4) 0, NULL,
                      (ub4) 0, FALSE, (ub4) OCI_DEFAULT);
  if (status == OCI_ERROR) {
    checkerr(errhp, status);
    // Clean up the handles, if required
    cleanup(svchp, authInfop, inserthp, stmthp);
    return OCI_ERROR;
  }

  logged_on = TRUE;
  printf("Connected to the database successfully.\n");

  /** Stage 2: Execute the SQL statements */

  /* retrieve the current maximum employee number */
  checkerr(errhp, OCIStmtPrepare2(svchp,(OCIStmt **)&stmthp, errhp, selmaxemp,
                                (ub4) strlen((char *) selmaxemp), NULL, 0,
                                (ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT));

  /* define the output variable for the select-list. */
  checkerr(errhp, OCIDefineByPos(stmthp, &defnp, errhp, 1, (dvoid *) &empno,
                                (sword) sizeof(sword), SQLT_INT, (dvoid *) 0,
                                (ub2 *) 0, (ub2 *)0, OCI_DEFAULT));

  /* execute and fetch */
  if (status = OCIStmtExecute(svchp, stmthp, errhp, (ub4) 1, (ub4) 0,
               (const OCISnapshot *) NULL, (OCISnapshot *) NULL, OCI_DEFAULT))
  {
    if (status == OCI_NO_DATA) // No rows found
      empno = 10;
    else
    {
      checkerr(errhp, status);
      cleanup(svchp, authInfop, inserthp, stmthp);
      return OCI_ERROR;
    }
  }

  checkerr(errhp, OCIStmtRelease((OCIStmt *)stmthp, errhp, (OraText *) NULL,
                                (ub4) 0, (ub4) OCI_DEFAULT));

  /* Keep inserting data till the user exits the application */
  for (;;)
  {
    // the employee name buffer size is ENAME_MAXLEN + 2 to allow for \n & \0
    ename = (OraText *) malloc((size_t) (ENAME_MAXLEN + 2) * sizeof(OraText));

    /* Prompt for employee name.  Break on no name. */
    printf("Enter employee name (or Enter to EXIT): ");
    fgets((char *) ename, (int) ENAME_MAXLEN + 1, stdin);
    cp = (OraText *) strchr((char *) ename, '\n');
    if (cp == ename)
    {
      printf("Exiting...\n");
      cleanup(svchp, authInfop, inserthp, stmthp);
      free_buffers(&ename, &job, &dept);
      return OCI_SUCCESS;
    }
    if (cp)
      *cp = '\0';
    else
    {
      printf("Employee name may be truncated.\n");
      myfflush();
    }

    // the job buffer size is JOB_MAXLEN + 2 to allow for \n and \0
    job = (OraText *) malloc((size_t) (JOB_MAXLEN + 2) * sizeof(OraText));

    /* Prompt for employee job and salary */
    printf("Enter employee job: ");
    job_ind = 0;
    fgets((char *) job, (int) JOB_MAXLEN + 1, stdin);
    cp = (OraText *) strchr((char *) job, '\n');
    if (cp == job)
    {
      job_ind = -1;             // make it NULL in the table
      printf("Job is NULL.\n"); // using indicator variable
    }
    else if (cp == 0)
    {
      printf("Job description may be truncated.\n");
      myfflush();
    }
    else
      *cp = '\0';
    printf("Enter employee salary: ");
    scanf("%f", &sal);
    myfflush();
    sal_ind = (sal <= 0) ? -1 : 0;  // set indicator variable

    /* prepare the INSERT statement */
    checkerr(errhp, OCIStmtPrepare2(svchp, (OCIStmt **) &inserthp, errhp,
                                  insert, (ub4) strlen((char *) insert), NULL,
                                  0, (ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT));

    /* bind the placeholders in the INSERT statement */
    if ((status = OCIBindByName(inserthp, &bnd1p, errhp, (OraText *) ":ENAME",
                  -1, (dvoid *) ename,
                  ENAME_MAXLEN + 1, SQLT_STR, (dvoid *) 0,
                  (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT)) ||
        (status = OCIBindByName(inserthp, &bnd2p, errhp, (OraText *) ":JOB",
                  -1, (dvoid *) job,
                  JOB_MAXLEN + 1, SQLT_STR, (dvoid *) &job_ind,
                  (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT)) ||
        (status = OCIBindByName(inserthp, &bnd3p, errhp, (OraText *) ":SAL",
                  -1, (dvoid *) &sal,
                  (sword) sizeof(sal), SQLT_FLT, (dvoid *) &sal_ind,
                  (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT)) ||
        (status = OCIBindByName(inserthp, &bnd4p, errhp, (OraText *) ":DEPTNO",
                  -1, (dvoid *) &deptno,
                  (sword) sizeof(deptno), SQLT_INT, (dvoid *) 0,
                  (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT)) ||
        (status = OCIBindByName(inserthp, &bnd5p, errhp, (OraText *) ":EMPNO",
                  -1, (dvoid *) &empno,
                  (sword) sizeof(empno), SQLT_INT, (dvoid *) 0,
                  (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT)))
    {
      checkerr(errhp, status);
      cleanup(svchp, authInfop, inserthp, stmthp);
      free_buffers(&ename, &job, &dept);
      return OCI_ERROR;
    }

    /* prepare the "seldept" statement */
    checkerr(errhp, OCIStmtPrepare2(svchp, (OCIStmt **) &stmthp, errhp,
                                  seldept, (ub4) strlen((char *) seldept),
                                  NULL, 0, (ub4) OCI_NTV_SYNTAX,
                                  (ub4) OCI_DEFAULT));

    /* bind the placeholder in the "seldept" statement */
    if (status = OCIBindByPos(stmthp, &bnd6p, errhp, 1,
                (dvoid *) &deptno, (sword) sizeof(deptno), SQLT_INT,
                (dvoid *) 0, (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0,
                OCI_DEFAULT))
    {
      checkerr(errhp, status);
      cleanup(svchp, authInfop, inserthp, stmthp);
      free_buffers(&ename, &job, &dept);
      return OCI_ERROR;
    }

    /* allocate the dept buffer now that you have length */
    dept = (OraText *) malloc((size_t) (DEPTNAME_MAXLEN + 1)
                            * sizeof(OraText));

    /* define the output variable for the select-list. */
    if (status = OCIDefineByPos(stmthp, &defnp, errhp, 1,
                (dvoid *) dept, DEPTNAME_MAXLEN + 1, SQLT_STR,
                (dvoid *) 0, (ub2 *) 0, (ub2 *) 0, OCI_DEFAULT))
    {
      checkerr(errhp, status);
      cleanup(svchp, authInfop, inserthp, stmthp);
      free_buffers(&ename, &job, &dept);
      return OCI_ERROR;
    }

    /*
     *  Prompt for the employee's department number, and verify that the
     *  entered department number is valid by fetching the corresponding data
     *  in the 'dept' table.
     */
    do
    {
      printf("Enter employee dept number: ");
      scanf("%d", &deptno);
      myfflush();
      /* execute the "seldept" statement */
      status = OCIStmtExecute(svchp, stmthp, errhp, (ub4) 1, (ub4) 0,
                    (const OCISnapshot *) NULL, (OCISnapshot *) NULL,
                    OCI_DEFAULT);
      if (status != OCI_SUCCESS && status != OCI_NO_DATA)
      {
        checkerr(errhp, status);
        cleanup(svchp, authInfop, inserthp, stmthp);
        free_buffers(&ename, &job, &dept);
        return OCI_ERROR;
      }
      if (status == OCI_NO_DATA)
        printf("The department number you entered doesn't exist.\n");
    } while (status == OCI_NO_DATA);

    /* release the select statement handle */
    checkerr(errhp, OCIStmtRelease((OCIStmt *) stmthp, errhp, (OraText *) NULL,
                                (ub4) 0, (ub4) OCI_DEFAULT));

    /*
      *  Increment empno (which currently holds the highest employee number)
      *  by 10, and execute the INSERT statement.
      */
    empno += 10;
    /* execute the INSERT statement */
    status = OCIStmtExecute(svchp, inserthp, errhp, (ub4) 1, (ub4) 0,
                          (const OCISnapshot *) NULL, (OCISnapshot *) NULL,
                          OCI_DEFAULT);
    if (status != OCI_SUCCESS)
    {
      checkerr(errhp, status);
      cleanup(svchp, authInfop, inserthp, stmthp);
      free_buffers(&ename, &job, &dept);
      return OCI_ERROR;
    }

    /* release the insert statement handle */
    checkerr(errhp, OCIStmtRelease((OCIStmt *) inserthp, errhp, (OraText *) NULL,
                                (ub4) 0, (ub4) OCI_DEFAULT));

    /** Stage 3: Commit the change and then free the handles and buffers */

    if (status = OCITransCommit(svchp, errhp, 0))
    {
      checkerr(errhp, status);
      cleanup(svchp, authInfop, inserthp, stmthp);
      free_buffers(&ename, &job, &dept);
      return OCI_ERROR;
    }
    printf("\n%s added to the %s department as employee number %d\n",
                ename, dept, empno);
    free_buffers(&ename, &job, &dept);
  }
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
    (void) OCIErrorGet((dvoid *) errhp, (ub4) 1, (OraText *) NULL, &errcode,
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

/* ----------------------------------------------------------------- */
/* Flushes the characters from standard input                        */
/* ----------------------------------------------------------------- */
void myfflush()
{
  eb1 buf[50];

  fgets((char *) buf, 50, stdin);
}

/* ----------------------------------------------------------------- */
/*  Free the query-related buffers                                   */
/* ----------------------------------------------------------------- */
void free_buffers(OraText **p_ename, OraText **p_job, char **p_dept) {
  if (*p_ename) {
    free(*p_ename);
    *p_ename = NULL;
  }

  if (*p_job) {
    free(*p_job);
    *p_job = NULL;
  }

  if (*p_dept) {
    free(*p_dept);
    *p_dept = NULL;
  }
}

/*---------------------------------------------------------------------*/
/* Finish demo and clean up                                            */
/*---------------------------------------------------------------------*/
sword cleanup(OCISvcCtx *svchp, OCIAuthInfo *authInfop, OCIStmt *inserthp,
  OCIStmt *stmthp)
{

  if (logged_on) {
    if ((status = OCISessionRelease(svchp, errhp, NULL, (ub4) 0,
                (ub4) OCI_DEFAULT)))
    {
      printf("FAILED: OCISessionRelease()\n");
      checkerr(errhp, status);
    }
  }

  /* Release all statement handles */
  if (inserthp)
    (void) OCIStmtRelease((OCIStmt *) inserthp, errhp, (OraText *) NULL,
                        (ub4) 0, (ub4) OCI_DEFAULT);
  if (stmthp)
    (void) OCIStmtRelease((OCIStmt *) stmthp, errhp, (OraText *) NULL,
                        (ub4) 0, (ub4) OCI_DEFAULT);
  if (stmthp)
    (void) OCIStmtRelease((OCIStmt *) stmthp, errhp, (OraText *) NULL,
                        (ub4) 0, (ub4) OCI_DEFAULT);

  /* Free all the OCI handles allocated by OCIHandleAlloc and env handle */
  if (authInfop)
    (void) OCIHandleFree((dvoid *) authInfop, (ub4) OCI_HTYPE_AUTHINFO);
  if (errhp)
    (void) OCIHandleFree((dvoid *) errhp, (ub4) OCI_HTYPE_ERROR);
  if (envhp)
    (void) OCIHandleFree((dvoid *) envhp, (ub4) OCI_HTYPE_ENV);

  OCITerminate(OCI_DEFAULT);

  return OCI_SUCCESS;
}
