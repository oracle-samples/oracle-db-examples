#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <oci.h>

static OCIEnv           *p_env;
static OCIError         *p_err;
static OCISvcCtx        *p_svc;
static OCIStmt          *p_sql;
static OCIDefine        *p_dfn    = (OCIDefine *) 0;
static OCIBind          *p_bnd    = (OCIBind *) 0;

static int reparse = 0;

int oci_setup() {
  int             p_bvi;
  char            p_sli[20];
  int             rc;
  char            errbuf[100];
  int             errcode;

  printf("Connecting to Oracle...");

  rc = OCIInitialize((ub4) OCI_DEFAULT, (dvoid *)0,  /* Initialize OCI */
          (dvoid * (*)(dvoid *, size_t)) 0,
          (dvoid * (*)(dvoid *, dvoid *, size_t))0,
          (void (*)(dvoid *, dvoid *)) 0 );

  /* Initialize evironment */
  rc = OCIEnvInit( (OCIEnv **) &p_env, OCI_DEFAULT, (size_t) 0, (dvoid **) 0 );

  /* Initialize handles */
  rc = OCIHandleAlloc( (dvoid *) p_env, (dvoid **) &p_err, OCI_HTYPE_ERROR,
          (size_t) 0, (dvoid **) 0);
  rc = OCIHandleAlloc( (dvoid *) p_env, (dvoid **) &p_svc, OCI_HTYPE_SVCCTX,
          (size_t) 0, (dvoid **) 0);

  /* Connect to database server */
  rc = OCILogon(p_env, p_err, &p_svc, "roger", 5, "roger", 5, "dbm1", 4);
  if (rc != 0) {
     OCIErrorGet((dvoid *)p_err, (ub4) 1, (text *) NULL, &errcode, errbuf, (ub4) sizeof(errbuf), OCI_HTYPE_ERROR);
     printf("Error - %.*sn", 512, errbuf);
     exit(8);
  }
  else {
    printf("Connected.\n");
    return 0;
  }
}

void checkerr(errhp, status)
OCIError *errhp;
sword status;
{
  text errbuf[512];
  ub4 buflen;
  ub4 errcode;

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
    (void) OCIErrorGet (errhp, (ub4) 1, (text *) NULL, &errcode,
                    errbuf, (ub4) sizeof(errbuf), OCI_HTYPE_ERROR);
    (void) printf("Error - %s\n", errbuf);
    break;
  case OCI_INVALID_HANDLE:
    (void) printf("Error - OCI_INVALID_HANDLE\n");
    break;
  case OCI_STILL_EXECUTING:
    (void) printf("Error - OCI_STILL_EXECUTE\n");
    break;
default:
    break;
  }
}

int execute_sql( char *sqlstring ) {
  int rc;

  /* printf( "Executing SQL: %s\n", sqlstring ); */

  /* Allocate and prepare SQL statement */
  rc = OCIHandleAlloc( (dvoid *) p_env, (dvoid **) &p_sql,
          OCI_HTYPE_STMT, (size_t) 0, (dvoid **) 0);
  rc = OCIStmtPrepare(p_sql, p_err, sqlstring,
                      (ub4) strlen(sqlstring), (ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT);

  /* Execute the SQL statment */
  rc = OCIStmtExecute(p_svc, p_sql, p_err, (ub4) 1, (ub4) 0,
          (CONST OCISnapshot *) NULL, (OCISnapshot *) NULL, OCI_DEFAULT);

  if( rc != OCI_SUCCESS ) {
    printf("SQL execution failure\n");
    checkerr(p_err, rc);
  }
}

int prepare( char *sqlstring ) {
  int rc;

  rc = OCIHandleAlloc( (dvoid *) p_env, (dvoid **) &p_sql,
                         OCI_HTYPE_STMT, (size_t) 0, (dvoid **) 0);

  rc = OCIStmtPrepare(p_sql, p_err, sqlstring,
                        (ub4) strlen(sqlstring), (ub4) OCI_NTV_SYNTAX, (ub4) OCI_DEFAULT);
  checkerr(p_err, rc);

}

int bind_and_execute( ub4 id, char *content ) {
  int rc;
  int p_bvi;
  
  p_bvi = id;
  /* Bind the values for the bind variables */
  rc = OCIBindByName(p_sql, &p_bnd, p_err, (text *) ":i",
                     -1, (dvoid *) &p_bvi, sizeof(int), SQLT_INT, (dvoid *) 0,
                     (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT);
  
  
  /* printf("Binding...\n"); */
  rc = OCIBindByName(p_sql, &p_bnd, p_err, (text *) ":x",
                     (sb4) strlen((char *) ":x"), (dvoid *) content, (sb4) strlen(content), SQLT_CHR, (dvoid *) 0,
                     (ub2 *) 0, (ub2 *) 0, (ub4) 0, (ub4 *) 0, OCI_DEFAULT);
  
  checkerr(p_err, rc);
  
  /* Execute the SQL statment */
  /* printf("Executing...\n"); */
  rc = OCIStmtExecute(p_svc, p_sql, p_err, (ub4) 1, (ub4) 0,
                      (CONST OCISnapshot *) NULL, (OCISnapshot *) NULL, OCI_DEFAULT);
  
  if( rc != OCI_SUCCESS ) {
    printf("SQL execution failure\n");
    checkerr(p_err, rc);
  }
  /* printf("Done\n"); */
}



int main( int argc, char ** argv ) {

  /********* USER CONFIGURABLE ************/
  int num_docs;         /* = 5000000; now a program argument */
  int num_partitions    = 1;   /* override with second arg */
  char tab_name[]       = "mydocs2";

  int max_words_per_doc = 500;
  int max_word_length   = 8;

  char consonents[]     = "BCDFG";
  char vowels[]         = "AEIO";
  int  commit_after     = 1;
  /********* END USER CONFIGURABLE ********/

  int num_vowels        = strlen(vowels);
  int num_consonents    = strlen(consonents);
  int range_step        = num_docs / num_partitions;
  int range_limit       = range_step;
  int p_num             = 1;
  char comma            = ' ';
  char word[max_word_length+1];


  char sql[2000];
  char insert_sql[2000];

  char buff[4000];
  int ret;

  /* Do the DDL to drop and create table */
  /***************************************/

  if( argc < 2 || argc > 3 ) {
    fprintf( stderr, "usage: %s <number_docs> [<number_partitions>]\n", argv[0] );
    exit( -1 );
  }
  else {
    num_docs = atoi(argv[1]);
    if( num_docs < 1 ) {
      fprintf( stderr, "usage: %s <number_docs> [<number_partitions>]\n", argv[0] );
      fprintf( stderr, "number_docs must be a positive integer\n");
      exit( -1 );
    }
    if( argc == 3 ) {
      num_partitions = 0;
      num_partitions = atoi(argv[2]);
    
      if( num_partitions < 1 ) {
	fprintf( stderr, "usage: %s <number_docs> [<number_partitions>]\n", argv[0] );
	fprintf( stderr, "number of partitions must be a positive integer\n" );
        exit( -1 );
      }
    
      if( num_partitions > num_docs ) {
	fprintf( stderr, "usage: %s <number_docs> [<number_partitions>]\n", argv[0] );
	fprintf( stderr, "number of docs must be >= number of partitions\n" );
        exit( -1 );
      }
    }
  }

  ret = oci_setup();

  strcpy( buff, "" );
  sprintf( insert_sql, "update %s set text = :x where id = :i", tab_name );
  prepare( insert_sql );
  printf ( insert_sql );

  int docnum;
  int rc;

  /* for each doc */
  for( docnum = 1; docnum <= num_docs; docnum++ ) {

    int words_in_this_doc = (rand() % max_words_per_doc) + 1;
    int wordnum;

    /* for each word */
    for( wordnum = 1; wordnum <= words_in_this_doc; wordnum++ ) {

      int chars_in_this_word = (rand() % max_word_length) + 1;

      /* for each char */
      int k;
      for( k = 0; k < chars_in_this_word;  ) {
	int remainder = k % 2;
        if( remainder ) {
	  word[k] = vowels[rand() % num_vowels];
	}
	else {
	  word[k] = consonents[rand() % num_consonents];
	}
        k++;
      }
      word[k] = '\0';

      /* check it doesn't exceed 40000 chars */
      if ( strlen(buff) + strlen(word) < 3998 ) {
        sprintf(buff, "%s %s ", buff, word);
      }
    }

    bind_and_execute( docnum, buff );

    /* Commit every 1000 rows and at end */
    if( ! ( docnum % commit_after ) ) {
      rc = OCITransCommit(p_svc, p_err, (ub4)0);
      checkerr(p_err, rc);
      printf("Commit done at %d rows\n", (docnum));
      /* prepare( insert_sql ); */
    }
  }
  rc = OCITransCommit(p_svc, p_err, (ub4)0);
  checkerr(p_err, rc);
  printf("Commit at %d rows\n", (docnum-1));
}

