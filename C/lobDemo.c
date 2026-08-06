/* Copyright (c) 2025, Oracle and/or its affiliates.*/
/* All rights reserved.*/

/*
  NAME
	lobDemo.c - C Demo program to illustrate the OCI Lob interface.

  DESCRIPTION
	This C file contains code to demonstrate the use of the OCI Large
    Objects (LOBs).
*/

#ifndef OCI_ORACLE
#include <oci.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*---------------------------------------------------------------------------
   TYPES AND CONSTANTS
---------------------------------------------------------------------------*/
#define LONGTEXTLENGTH 1024
#define BUFSIZE 1024

#define FAILURE 1
#define SUCCESS 0

#define DATA_SOURCE_FILE "<data file name>"

static const OraText *insstmt =
	"INSERT INTO CLBTAB VALUES ( 'Jack', EMPTY_CLOB())";

static const OraText *selstmt[2] =
	{
		"SELECT essay FROM CLBTAB WHERE name = 'Jack' for update",
		"SELECT essay FROM CLBTAB WHERE name = 'Jack'"};

static char *username = "<username>";
static char *password = "<password>";
static char *connstr = "<connect string>";

/* GLOBAL STRUCTURE */
typedef struct
{										 
	OCIEnv *envhp;		 /* Environment handle */
	OCISvcCtx *svchp;	 /* Service handle */
	OCIError *errhp;	 /* Error handle */
	OCIAuthInfo *authp;  /* Authentication handle */
} context;

/* define macros to be comment on the function status updates */
#define COMMENT(x) (void)fprintf(stdout, "\nCOMMENT: %s\n", x)

/*---------------------------------------------------------------------------
  FUNCTIONS
---------------------------------------------------------------------------*/
static context *alloc_handles();
static void cleanup(context *ctx);
static void errrpt(context *ctx, const OraText *op);
static void checkenverr(OCIEnv *errhp, sword status);
static void authenticate_user(context *ctx);
static void deauthenticate(context *ctx);

static void insert_select_loc(context *ctx, dvoid *lobsrc);
static void select_loc_data(context *ctx);

static sword write_to_loc(context *ctx, OCILobLocator *lobp);
static sword read_from_loc(context *ctx, OCILobLocator *lobp,
						boolean readAllLobData);

/* ----------------------------------------------------------------- */
/*  Main function definition                                         */
/* ----------------------------------------------------------------- */
int main(void)
{
	context *ctx;
	OCILobLocator *lobp;
	sword retval;

	/* allocate required handles and connect to the database */
	ctx = alloc_handles();
	authenticate_user(ctx);

	/* allocate memory for the lob locator */
	if (OCIDescriptorAlloc((dvoid *) ctx->envhp, (dvoid **) &lobp,
                      (ub4) OCI_DTYPE_LOB, (size_t) 0,
						          (dvoid **) 0) != OCI_SUCCESS)
	{
		errrpt(ctx, (const OraText *) "OCIDescriptorAlloc");
		cleanup(ctx);
		return FAILURE;
	}

	/* insert an empty lob and allocate the lob locator to the empty lob */
	insert_select_loc(ctx, lobp);

	/* write data into the lob using the lob locator */
	retval = write_to_loc(ctx, lobp);
	if (retval == FAILURE) {
		deauthenticate(ctx);
		cleanup(ctx);
		return FAILURE;
	}

	/* read a portion of data from the lob using the lob locator */
	retval = read_from_loc(ctx, lobp, FALSE);
	if (retval == FAILURE) {
		deauthenticate(ctx);
		cleanup(ctx);
		return FAILURE;
	}

	/* free the lob locator */
	(void)OCIDescriptorFree((dvoid *) lobp, (ub4)OCI_DTYPE_LOB);

	/* read the complete data from the lob column using SQLT_CLOB */
	select_loc_data(ctx);

	/* deauthenticate (logout) user and cleanup handles */
	deauthenticate(ctx);
	cleanup(ctx);

	return SUCCESS;
}

/*-------------------------------------------------------------------------*/
/* Allocate and initialise global and local context structures.            */
/*-------------------------------------------------------------------------*/
static context *alloc_handles()
{
	context *ctxp;
	sword status = 0;
	ctxp = (context *) malloc(sizeof(context));
	if (ctxp == (context *) 0)
	{
		COMMENT("Unable To Allocate Memory for context ...");
		exit(FAILURE);
	}
	memset((void *) ctxp, '\0', sizeof(context));

  /* create environment handle */
	if ((status = OCIEnvCreate((OCIEnv **) &ctxp->envhp, (ub4) OCI_DEFAULT,
							            (dvoid *) 0, (dvoid * (*)(dvoid *, size_t)) 0,
							            (dvoid * (*)(dvoid *, dvoid *, size_t)) 0,
							            (void (*)(dvoid *, dvoid *))0, (size_t) 0,
							            (dvoid **) 0)) != OCI_SUCCESS)
	{
		COMMENT("Failed to create environment handle...");
		checkenverr(ctxp->envhp, status);
		cleanup(ctxp);
		exit(FAILURE);
	}

	/* get error handle */
	if (OCIHandleAlloc((dvoid *) ctxp->envhp, (dvoid **) &ctxp->errhp,
					(ub4) OCI_HTYPE_ERROR, (size_t) 0,
					(dvoid **) 0) != OCI_SUCCESS)
	{
		COMMENT("Failed to allocate error handle...");
		cleanup(ctxp);
		exit(FAILURE);
	}

	/* get auth context */
	if (OCIHandleAlloc((dvoid *) ctxp->envhp, (dvoid **) &ctxp->authp,
					(ub4) OCI_HTYPE_AUTHINFO, (size_t) 0,
					(dvoid **) 0) != OCI_SUCCESS)
	{
		COMMENT("Failed to allocate auth handle...");
		cleanup(ctxp);
		exit(FAILURE);
	}

	return ctxp;
}

/*-------------------------------------------------------------------------*/
/* Authenticate users and connect to Oracle Database                       */
/*-------------------------------------------------------------------------*/
static void authenticate_user(context *ctx)
{
	COMMENT("Authentication for the user is in progress...");

	/* set the username/password in authentication handle */
	if (OCIAttrSet(ctx->authp, OCI_HTYPE_AUTHINFO,
				      (dvoid *) username, (ub4) strlen((char *) username),
				      OCI_ATTR_USERNAME, ctx->errhp) != OCI_SUCCESS)
		errrpt(ctx, (const OraText *) "conn2serv - OCIAttrSet");

	if (OCIAttrSet(ctx->authp, OCI_HTYPE_AUTHINFO,
              (dvoid *) password, (ub4) strlen((char *) password),
				      OCI_ATTR_PASSWORD, ctx->errhp) != OCI_SUCCESS)
		errrpt(ctx, "conn2serv - OCIAttrSet");

	/* Authenticate */
	if (OCISessionGet(ctx->envhp, ctx->errhp, &ctx->svchp, ctx->authp,
  					      (OraText *) connstr, (ub4) strlen((char *) connstr),
					        NULL, (ub4) 0, NULL, (ub4) 0, FALSE,
					        (ub4) OCI_DEFAULT) != OCI_SUCCESS)
		errrpt(ctx, "conn2serv - OCISessionGet");

	COMMENT("Authentication for the user successful.");
}

/* --------------------------------------------------------------------- */
/* Insert one row into table and select the lob locator.                 */
/* --------------------------------------------------------------------- */
static void insert_select_loc(context *ctx, dvoid *lobsrc)
{
	OCIStmt *inserthp = NULL, // for insert statement
			*selecthp = NULL; // for select-for-update statement
	OCIDefine *defnhp  = (OCIDefine *) 0;

	/* insert an empty locator */
	if (OCIStmtPrepare2(ctx->svchp, (OCIStmt **) &inserthp, ctx->errhp,
					        insstmt, (ub4) strlen((char *) insstmt) + 1, NULL, 0,
					        OCI_NTV_SYNTAX, OCI_DEFAULT) != OCI_SUCCESS)
		errrpt(ctx, (const OraText *) "insert_select_loc: OCIStmtPrepare2");

	if (OCIStmtExecute(ctx->svchp, inserthp, ctx->errhp, 1, 0, 0, 0,
                  OCI_DEFAULT) != OCI_SUCCESS)
    errrpt(ctx, (const OraText *)" insert_select_loc: OCIStmtExecute");

  printf("Inserted LOB data\n");

  /* release statement handle */
  if (OCIStmtRelease((OCIStmt *) inserthp, (OCIError *) ctx->errhp,
                  (dvoid *) NULL, 0, OCI_DEFAULT) != OCI_SUCCESS)
    errrpt(ctx, (const OraText *) "insert_select_loc: OCIStmtRelease");

	/* now select the locator */
	if (OCIStmtPrepare2(ctx->svchp, (OCIStmt **) &(selecthp), ctx->errhp,
					        selstmt[0], (ub4) strlen((char *)selstmt[0]) + 1, NULL, 0,
					        OCI_NTV_SYNTAX, OCI_DEFAULT) != OCI_SUCCESS)
		errrpt(ctx, (const OraText *) "insert_select_loc: OCIStmtPrepare2");

  /* call define for each column of interest */
  if (OCIDefineByPos(selecthp, &defnhp, ctx->errhp, 1, (dvoid *) &lobsrc,
                  0, SQLT_CLOB, (dvoid *) 0, (ub2 *) 0,
                  (ub2 *) 0, OCI_DEFAULT) != OCI_SUCCESS)
    errrpt(ctx, (const OraText *) "insert_select_loc: OCIDefineByPos");

  printf("About to select locator...\n");

  if (OCIStmtExecute(ctx->svchp, selecthp, ctx->errhp, 1, 0, 0, 0,
                  OCI_DEFAULT) != OCI_SUCCESS)
    errrpt(ctx, (const OraText *) "insert_select_loc: OCIStmtExecute");

  /* release statement handle */
  if (OCIStmtRelease((OCIStmt *) selecthp, (OCIError *) ctx->errhp,
                  (dvoid *) NULL, 0, OCI_DEFAULT) != OCI_SUCCESS)
    errrpt(ctx, (const OraText *) "insert_select_loc: OCIStmtRelease");
}

/* --------------------------------------------------------------------- */
/* Write data into the selected lob locator                              */
/* --------------------------------------------------------------------- */
sword write_to_loc(context *ctx, OCILobLocator *lobp)
{
	FILE *fp;
	ub1 buf[BUFSIZE + 1];
	oraub8 offset;
	oraub8 amtp;
	oraub8 lenp;
	sb4 err;

	/* Check if the file exists and can be opened */
	if ((fp = fopen(DATA_SOURCE_FILE, "r")) == NULL)
	{
		COMMENT("Cannot open source file for reading");
		fprintf(stderr, "Error opening file '%s'\n", DATA_SOURCE_FILE);
		return FAILURE;
	}

	offset = 1; /* Offset for lobs start at 1 */

	while (!feof(fp))
	{
		/* read the data from file */
		memset((void *) buf, '\0', BUFSIZE);
		fread((void *) buf, BUFSIZE, 1, fp);
		buf[BUFSIZE] = '\0';

		/* write it into the locator */
		amtp = BUFSIZE; /* IN/OUT : IN - amount of data to write */
		err = OCILobWrite2(ctx->svchp, ctx->errhp, lobp, &amtp, NULL, offset,
						        (dvoid *) buf, (ub4) BUFSIZE, OCI_ONE_PIECE, (dvoid *) 0,
						        (sb4 (*)()) 0, (ub2) 0, (ub1) SQLCS_IMPLICIT);
		if (err == OCI_SUCCESS)
		{
			printf("Written some data into the LOB...\n");
			offset += amtp;
		}
		else
		{
			fclose(fp);
			errrpt(ctx, (const OraText *) "write_to_loc : OCILobWrite");
		}
	}

	COMMENT("Write to the LOB successful");
	/* length of the lob data */
	err = OCILobGetLength2(ctx->svchp, ctx->errhp, lobp, &lenp);
	if (err != OCI_SUCCESS)
		printf("   Get lob length fails. err = %d\n\n", err);
	else
		printf("   Written %d bytes into locator successfully.\n", lenp);

	fclose(fp);
	return SUCCESS;
}

/* --------------------------------------------------------------------- */
/* Read data from the lob locator                                        */
/* --------------------------------------------------------------------- */
sword read_from_loc(context *ctx, OCILobLocator *lobp, boolean readAllLobData)
{
	ub1 buf[BUFSIZE + 1];
	oraub8 offset;
	oraub8 amtp = (oraub8) BUFSIZE; /* default amount to be read value */
	oraub8 lenp = 0;

	ub1 piece;
	sb4 err;

	/* length of the lob */
	if (OCILobGetLength2(ctx->svchp, ctx->errhp, lobp, &lenp) != OCI_SUCCESS)
		errrpt(ctx, (const OraText *) "read_from_loc: OCILobGetLength2");
	else
		printf("Length of the LOB is %d\n", lenp);

	if (readAllLobData) {
		COMMENT("Reading the entire LOB data");
		printf("=====================================\n");
		offset = 1;
		amtp = lenp;
	} else {
		COMMENT("Reading from the locator");
		printf("==================================\n");
		for (;;)
		{
			printf("Enter the offset to read from (starting at 1): ");
			scanf("%ld", &offset);
			if (offset >= lenp)
			{
				printf("offset has to be less than the number of characters in\
					the file: %ld\n", lenp);
				continue;
			}
			break;
		}
		printf("Enter amount to read: ");
		scanf("%ld", &amtp);

		if ((offset + amtp - 1) > lenp)
		{
			printf("Error: Trying to get more data than available!\n");
			return FAILURE;
		}
	}
	printf(
		"\n------------------------------------------------------------------\n");

	/* read the lob locator in polling mode */
	piece = OCI_FIRST_PIECE;
	do
	{
		memset((dvoid *)buf, '\0', BUFSIZE);
		err = OCILobRead2(ctx->svchp, ctx->errhp, lobp, NULL, (oraub8 *) &amtp,
						        offset, (dvoid *) buf, (oraub8) BUFSIZE, piece,
						        (void *) 0, (OCICallbackLobRead2) 0, (ub2) 0,
						        (ub1) SQLCS_IMPLICIT);
		if (err == OCI_SUCCESS || err == OCI_NEED_DATA)
		{
			buf[BUFSIZE] = '\0';
			printf("%s", buf);
			offset += amtp;
		}
		else
			errrpt(ctx, (const OraText *) "read_from_loc : OCILobRead2");
		piece = OCI_NEXT_PIECE;
	} while (err == OCI_NEED_DATA);
	printf(
			"\n------------------------------------------------------------------\n");
	printf("\n");

	return SUCCESS;
}

/* --------------------------------------------------------------------- */
/* Select the lob data                                                   */
/* --------------------------------------------------------------------- */
static void select_loc_data(context *ctx)
{
	OCILobLocator *lobp;
	OCIStmt *stmthp = NULL; // for select statement
	OCIDefine *defnhp  = (OCIDefine *) 0;
	ub4 status = 0;
	sb2 outind = 0;
	sword retval;

	/* allocate the lob locator */
	if (OCIDescriptorAlloc((dvoid *) ctx->envhp, (dvoid **) &lobp,
						          (ub4) OCI_DTYPE_LOB,
						          (size_t) 0, (dvoid **) 0) != OCI_SUCCESS)
	{
		errrpt(ctx, (const OraText *) "OCIDescriptorAlloc in select_loc_data");
		cleanup(ctx);
		exit(FAILURE);
	}

	printf("\nSelect Locator Data as SQLT_CLOB\n");

	/* now select the locator */
	if (OCIStmtPrepare2(ctx->svchp, (OCIStmt **) &stmthp, ctx->errhp,
                    selstmt[1], (ub4) strlen((char *) selstmt[1]) + 1, NULL,
					          0, OCI_NTV_SYNTAX, OCI_DEFAULT) != OCI_SUCCESS)
		errrpt(ctx, (const OraText *) "select_loc_data: OCIStmtPrepare2");

  /* call define for each column of interest */
  if (OCIDefineByPos2(stmthp, &defnhp, ctx->errhp, 1, (dvoid *) &lobp,
                    0, SQLT_CLOB, (dvoid *) &outind, (ub4 *) 0, (ub2 *) 0,
                    OCI_DEFAULT) != OCI_SUCCESS)
    errrpt(ctx, (const OraText *) "select_loc_data: OCIDefineByPos2");

  if (OCIStmtExecute(ctx->svchp, stmthp, ctx->errhp, 0, 0, 0, 0,
                  OCI_DEFAULT) != OCI_SUCCESS)
    errrpt(ctx, (const OraText *) "select_loc_data: OCIStmtExecute");

  do
  {
    status = OCIStmtFetch2(stmthp, ctx->errhp, (ub4) 1,
                        (ub4) OCI_FETCH_NEXT, (sb4) 0, (ub4) OCI_DEFAULT);

    if (outind != 0)
      printf("Normal data not fetched, Output Indicator Value is %d\n",
        outind);

    if (status == OCI_SUCCESS || status == OCI_SUCCESS_WITH_INFO) {
      retval = read_from_loc(ctx, lobp, TRUE);
      if (retval == FAILURE) {
        deauthenticate(ctx);
        cleanup(ctx);
        exit(FAILURE);
      }
    }
    else
    {
      if (status != OCI_NO_DATA)
        errrpt(ctx, "on fetching the lob as char");
      break;
    }
  } while(0);

  printf("End of Reading Locator as SQLT_CLOB\n\n");

  /* Release statement handle */
  if (OCIStmtRelease((OCIStmt *) stmthp, (OCIError *) ctx->errhp,
                  (dvoid *) NULL, 0, OCI_DEFAULT) != OCI_SUCCESS)
    errrpt(ctx, (const OraText *)"select_loc_data: OCIStmtRelease");

  /* free the lob locator */
  (void) OCIDescriptorFree((dvoid *) lobp, (ub4)OCI_DTYPE_LOB);
}

/*-------------------------------------------------------------------------*/
/* Deauthenticate the user                                                 */
/*-------------------------------------------------------------------------*/
static void deauthenticate(context *ctx)
{
	if (OCISessionRelease(ctx->svchp, ctx->errhp, NULL, (ub4) 0,
                      OCI_DEFAULT) != OCI_SUCCESS)
		errrpt(ctx, (const OraText *) "logout: OCISessionRelease");
	COMMENT("Logged off.\n");
}

/* -------------------------------------------------------------- */
/*  Clean up all structures used.                                 */
/* -------------------------------------------------------------- */
static void cleanup(context *ctx)
{
	if (ctx->errhp)
		(void) OCIHandleFree((dvoid *) ctx->errhp, (ub4) OCI_HTYPE_ERROR);
	if (ctx->authp)
		(void) OCIHandleFree((dvoid *) ctx->authp, (ub4) OCI_HTYPE_SESSION);
	(void) OCIHandleFree((dvoid *) ctx->envhp, (ub4) OCI_HTYPE_ENV);

	free(ctx);
}

/* ------------------------------------------------------------------------- */
/* Format the output error message and obtain error string from Oracle       */
/* Database, given the error code                                            */
/* ------------------------------------------------------------------------- */
void errrpt(context *ctx, const OraText *op)
{
	OraText msgbuf[LONGTEXTLENGTH];
	sb4 errcode = 0;

	fprintf(stdout, "ORACLE error during %s\n", op);
	OCIErrorGet((dvoid *)ctx->errhp, (ub4)1, (OraText *)NULL, &errcode,
						msgbuf, (ub4) sizeof(msgbuf), (ub4) OCI_HTYPE_ERROR);
	fprintf(stdout, "ERROR CODE = %d\n", errcode);
	fprintf(stdout, "%s\n", msgbuf);
	cleanup(ctx);
	exit(FAILURE);
}

/* ----------------------------------------------------------------- */
/*  OCIEnvCreate error checking routine                              */
/* ----------------------------------------------------------------- */
static void checkenverr(OCIEnv *envhp, sword status)
{
	OraText errbuf[512];
	ub4 errcode;

	switch (status)
	{
	case OCI_SUCCESS_WITH_INFO:
		printf("Error - OCI_SUCCESS_WITH_INFO\n");
		break;
	case OCI_ERROR:
		OCIErrorGet((dvoid *)envhp, (ub4)1, (text *)NULL, (sb4 *)&errcode,
							errbuf, (ub4)sizeof(errbuf), (ub4)OCI_HTYPE_ENV);
		printf("Error - %s\n", errbuf);
		break;
	case OCI_INVALID_HANDLE:
		printf("Error - OCI_INVALID_HANDLE\n");
		break;
	default:
		break;
	}
}
