//-----------------------------------------------------------------------------
// Copyright (c) 2016-2018 Oracle and/or its affiliates.  All rights reserved.
// This program is free software: you can modify it and/or redistribute it
// under the terms of:
//
// (i)  the Universal Permissive License v 1.0 or at your option, any
//      later version (http://oss.oracle.com/licenses/upl); and/or
//
// (ii) the Apache License v 2.0. (http://www.apache.org/licenses/LICENSE-2.0)
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// dpiImpl.h
//   Master include file for implementation of ODPI-C library. The definitions
// in this file are subject to change without warning. Only the definitions in
// the file dpi.h are intended to be used publicly.
//-----------------------------------------------------------------------------

#ifndef DPI_IMPL
#define DPI_IMPL

// Visual Studio 2005 introduced deprecation warnings for "insecure" and POSIX
// functions; silence these warnings
#ifndef _CRT_SECURE_NO_WARNINGS
#define _CRT_SECURE_NO_WARNINGS 1
#endif

#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <ctype.h>
#include <limits.h>
#include <float.h>
#include <math.h>
#include "dpi.h"

#ifdef _WIN32
#include <windows.h>
#ifndef isnan
#define isnan			_isnan
#endif
#else
#include <pthread.h>
#include <sys/time.h>
#include <dlfcn.h>
#endif
#ifdef __linux
#include <unistd.h>
#include <sys/syscall.h>
#endif

#ifdef _MSC_VER
#if _MSC_VER < 1900
#define PRId64                  "I64d"
#define PRIu64                  "I64u"
#define snprintf                _snprintf
#endif
#endif

#ifndef PRIu64
#include <inttypes.h>
#endif

#ifdef __GNUC__
#define UNUSED __attribute((unused))
#else
#define UNUSED
#endif

// define debugging level (defined in dpiGlobal.c)
extern unsigned long dpiDebugLevel;

// define max error size
#define DPI_MAX_ERROR_SIZE                          3072

// define context name for ping interval
#define DPI_CONTEXT_LAST_TIME_USED                  "DPI_LAST_TIME_USED"

// define size of buffer used for numbers transferred to/from Oracle as text
#define DPI_NUMBER_AS_TEXT_CHARS                    172

// define maximum number of digits possible in an Oracle number
#define DPI_NUMBER_MAX_DIGITS                       40

// define maximum size in bytes supported by basic string handling
#define DPI_MAX_BASIC_BUFFER_SIZE                   32767

// define internal chunk size used for dynamic binding/fetching
#define DPI_DYNAMIC_BYTES_CHUNK_SIZE                65536

// define maximum buffer size permitted in variables
#define DPI_MAX_VAR_BUFFER_SIZE                     (1024 * 1024 * 1024 - 2)

// define number of rows to prefetch
#define DPI_PREFETCH_ROWS_DEFAULT                   2

// define well-known character sets
#define DPI_CHARSET_ID_ASCII                        1
#define DPI_CHARSET_ID_UTF8                         873
#define DPI_CHARSET_ID_UTF16                        1000
#define DPI_CHARSET_NAME_ASCII                      "ASCII"
#define DPI_CHARSET_NAME_UTF8                       "UTF-8"
#define DPI_CHARSET_NAME_UTF16                      "UTF-16"
#define DPI_CHARSET_NAME_UTF16LE                    "UTF-16LE"
#define DPI_CHARSET_NAME_UTF16BE                    "UTF-16BE"

// define handle types used for allocating OCI handles
#define DPI_OCI_HTYPE_ENV                           1
#define DPI_OCI_HTYPE_ERROR                         2
#define DPI_OCI_HTYPE_SVCCTX                        3
#define DPI_OCI_HTYPE_STMT                          4
#define DPI_OCI_HTYPE_BIND                          5
#define DPI_OCI_HTYPE_DEFINE                        6
#define DPI_OCI_HTYPE_DESCRIBE                      7
#define DPI_OCI_HTYPE_SERVER                        8
#define DPI_OCI_HTYPE_SESSION                       9
#define DPI_OCI_HTYPE_AUTHINFO                      9
#define DPI_OCI_HTYPE_TRANS                         10
#define DPI_OCI_HTYPE_SUBSCRIPTION                  13
#define DPI_OCI_HTYPE_SPOOL                         27

// define OCI descriptor types
#define DPI_OCI_DTYPE_LOB                           50
#define DPI_OCI_DTYPE_PARAM                         53
#define DPI_OCI_DTYPE_ROWID                         54
#define DPI_OCI_DTYPE_AQENQ_OPTIONS                 57
#define DPI_OCI_DTYPE_AQDEQ_OPTIONS                 58
#define DPI_OCI_DTYPE_AQMSG_PROPERTIES              59
#define DPI_OCI_DTYPE_INTERVAL_YM                   62
#define DPI_OCI_DTYPE_INTERVAL_DS                   63
#define DPI_OCI_DTYPE_TIMESTAMP                     68
#define DPI_OCI_DTYPE_TIMESTAMP_TZ                  69
#define DPI_OCI_DTYPE_TIMESTAMP_LTZ                 70
#define DPI_OCI_DTYPE_CHDES                         77
#define DPI_OCI_DTYPE_TABLE_CHDES                   78
#define DPI_OCI_DTYPE_ROW_CHDES                     79
#define DPI_OCI_DTYPE_CQDES                         80
#define DPI_OCI_DTYPE_SHARDING_KEY                  83

// define values used for getting/setting OCI attributes
#define DPI_OCI_ATTR_DATA_SIZE                      1
#define DPI_OCI_ATTR_DATA_TYPE                      2
#define DPI_OCI_ATTR_PRECISION                      5
#define DPI_OCI_ATTR_SCALE                          6
#define DPI_OCI_ATTR_NAME                           4
#define DPI_OCI_ATTR_SERVER                         6
#define DPI_OCI_ATTR_SESSION                        7
#define DPI_OCI_ATTR_IS_NULL                        7
#define DPI_OCI_ATTR_TRANS                          8
#define DPI_OCI_ATTR_TYPE_NAME                      8
#define DPI_OCI_ATTR_SCHEMA_NAME                    9
#define DPI_OCI_ATTR_ROW_COUNT                      9
#define DPI_OCI_ATTR_PREFETCH_ROWS                  11
#define DPI_OCI_ATTR_PARAM_COUNT                    18
#define DPI_OCI_ATTR_USERNAME                       22
#define DPI_OCI_ATTR_PASSWORD                       23
#define DPI_OCI_ATTR_STMT_TYPE                      24
#define DPI_OCI_ATTR_INTERNAL_NAME                  25
#define DPI_OCI_ATTR_EXTERNAL_NAME                  26
#define DPI_OCI_ATTR_XID                            27
#define DPI_OCI_ATTR_CHARSET_ID                     31
#define DPI_OCI_ATTR_CHARSET_FORM                   32
#define DPI_OCI_ATTR_MAXDATA_SIZE                   33
#define DPI_OCI_ATTR_ROWS_RETURNED                  42
#define DPI_OCI_ATTR_VISIBILITY                     47
#define DPI_OCI_ATTR_CONSUMER_NAME                  50
#define DPI_OCI_ATTR_DEQ_MODE                       51
#define DPI_OCI_ATTR_NAVIGATION                     52
#define DPI_OCI_ATTR_WAIT                           53
#define DPI_OCI_ATTR_DEQ_MSGID                      54
#define DPI_OCI_ATTR_PRIORITY                       55
#define DPI_OCI_ATTR_DELAY                          56
#define DPI_OCI_ATTR_EXPIRATION                     57
#define DPI_OCI_ATTR_CORRELATION                    58
#define DPI_OCI_ATTR_ATTEMPTS                       59
#define DPI_OCI_ATTR_EXCEPTION_QUEUE                61
#define DPI_OCI_ATTR_ENQ_TIME                       62
#define DPI_OCI_ATTR_MSG_STATE                      63
#define DPI_OCI_ATTR_ORIGINAL_MSGID                 69
#define DPI_OCI_ATTR_NUM_DML_ERRORS                 73
#define DPI_OCI_ATTR_DML_ROW_OFFSET                 74
#define DPI_OCI_ATTR_SUBSCR_NAME                    94
#define DPI_OCI_ATTR_SUBSCR_CALLBACK                95
#define DPI_OCI_ATTR_SUBSCR_CTX                     96
#define DPI_OCI_ATTR_SUBSCR_NAMESPACE               98
#define DPI_OCI_ATTR_REF_TDO                        110
#define DPI_OCI_ATTR_PARAM                          124
#define DPI_OCI_ATTR_PARSE_ERROR_OFFSET             129
#define DPI_OCI_ATTR_SERVER_STATUS                  143
#define DPI_OCI_ATTR_STATEMENT                      144
#define DPI_OCI_ATTR_DEQCOND                        146
#define DPI_OCI_ATTR_SUBSCR_RECPTPROTO              149
#define DPI_OCI_ATTR_CURRENT_POSITION               164
#define DPI_OCI_ATTR_STMTCACHESIZE                  176
#define DPI_OCI_ATTR_BIND_COUNT                     190
#define DPI_OCI_ATTR_TRANSFORMATION                 196
#define DPI_OCI_ATTR_ROWS_FETCHED                   197
#define DPI_OCI_ATTR_SPOOL_STMTCACHESIZE            208
#define DPI_OCI_ATTR_TYPECODE                       216
#define DPI_OCI_ATTR_STMT_IS_RETURNING              218
#define DPI_OCI_ATTR_CURRENT_SCHEMA                 224
#define DPI_OCI_ATTR_SUBSCR_QOSFLAGS                225
#define DPI_OCI_ATTR_COLLECTION_ELEMENT             227
#define DPI_OCI_ATTR_SUBSCR_TIMEOUT                 227
#define DPI_OCI_ATTR_NUM_TYPE_ATTRS                 228
#define DPI_OCI_ATTR_SUBSCR_CQ_QOSFLAGS             229
#define DPI_OCI_ATTR_LIST_TYPE_ATTRS                229
#define DPI_OCI_ATTR_SUBSCR_CQ_REGID                230
#define DPI_OCI_ATTR_NCHARSET_ID                    262
#define DPI_OCI_ATTR_APPCTX_SIZE                    273
#define DPI_OCI_ATTR_APPCTX_LIST                    274
#define DPI_OCI_ATTR_APPCTX_NAME                    275
#define DPI_OCI_ATTR_APPCTX_ATTR                    276
#define DPI_OCI_ATTR_APPCTX_VALUE                   277
#define DPI_OCI_ATTR_CLIENT_IDENTIFIER              278
#define DPI_OCI_ATTR_CHAR_SIZE                      286
#define DPI_OCI_ATTR_EDITION                        288
#define DPI_OCI_ATTR_CQ_QUERYID                     304
#define DPI_OCI_ATTR_SPOOL_TIMEOUT                  308
#define DPI_OCI_ATTR_SPOOL_GETMODE                  309
#define DPI_OCI_ATTR_SPOOL_BUSY_COUNT               310
#define DPI_OCI_ATTR_SPOOL_OPEN_COUNT               311
#define DPI_OCI_ATTR_MODULE                         366
#define DPI_OCI_ATTR_ACTION                         367
#define DPI_OCI_ATTR_CLIENT_INFO                    368
#define DPI_OCI_ATTR_SUBSCR_PORTNO                  390
#define DPI_OCI_ATTR_CHNF_ROWIDS                    402
#define DPI_OCI_ATTR_CHNF_OPERATIONS                403
#define DPI_OCI_ATTR_CHDES_DBNAME                   405
#define DPI_OCI_ATTR_CHDES_NFYTYPE                  406
#define DPI_OCI_ATTR_CHDES_XID                      407
#define DPI_OCI_ATTR_MSG_DELIVERY_MODE              407
#define DPI_OCI_ATTR_CHDES_TABLE_CHANGES            408
#define DPI_OCI_ATTR_CHDES_TABLE_NAME               409
#define DPI_OCI_ATTR_CHDES_TABLE_OPFLAGS            410
#define DPI_OCI_ATTR_CHDES_TABLE_ROW_CHANGES        411
#define DPI_OCI_ATTR_CHDES_ROW_ROWID                412
#define DPI_OCI_ATTR_CHDES_ROW_OPFLAGS              413
#define DPI_OCI_ATTR_CHNF_REGHANDLE                 414
#define DPI_OCI_ATTR_CQDES_OPERATION                422
#define DPI_OCI_ATTR_CQDES_TABLE_CHANGES            423
#define DPI_OCI_ATTR_CQDES_QUERYID                  424
#define DPI_OCI_ATTR_DRIVER_NAME                    424
#define DPI_OCI_ATTR_CHDES_QUERIES                  425
#define DPI_OCI_ATTR_CONNECTION_CLASS               425
#define DPI_OCI_ATTR_PURITY                         426
#define DPI_OCI_ATTR_RECEIVE_TIMEOUT                436
#define DPI_OCI_ATTR_UB8_ROW_COUNT                  457
#define DPI_OCI_ATTR_SPOOL_AUTH                     460
#define DPI_OCI_ATTR_LTXID                          462
#define DPI_OCI_ATTR_DML_ROW_COUNT_ARRAY            469
#define DPI_OCI_ATTR_ERROR_IS_RECOVERABLE           472
#define DPI_OCI_ATTR_TRANSACTION_IN_PROGRESS        484
#define DPI_OCI_ATTR_DBOP                           485
#define DPI_OCI_ATTR_SPOOL_MAX_LIFETIME_SESSION     490
#define DPI_OCI_ATTR_BREAK_ON_NET_TIMEOUT           495
#define DPI_OCI_ATTR_SHARDING_KEY                   496
#define DPI_OCI_ATTR_SUPER_SHARDING_KEY             497

// define OCI object type constants
#define DPI_OCI_OTYPE_NAME                          1
#define DPI_OCI_OTYPE_PTR                           3

// define OCI data type constants
#define DPI_SQLT_CHR                                1
#define DPI_SQLT_NUM                                2
#define DPI_SQLT_INT                                3
#define DPI_SQLT_FLT                                4
#define DPI_SQLT_VNU                                6
#define DPI_SQLT_LNG                                8
#define DPI_SQLT_VCS                                9
#define DPI_SQLT_DAT                                12
#define DPI_SQLT_BFLOAT                             21
#define DPI_SQLT_BDOUBLE                            22
#define DPI_SQLT_BIN                                23
#define DPI_SQLT_LBI                                24
#define DPI_SQLT_UIN                                68
#define DPI_SQLT_AFC                                96
#define DPI_SQLT_IBFLOAT                            100
#define DPI_SQLT_IBDOUBLE                           101
#define DPI_SQLT_RDD                                104
#define DPI_SQLT_NTY                                108
#define DPI_SQLT_CLOB                               112
#define DPI_SQLT_BLOB                               113
#define DPI_SQLT_BFILE                              114
#define DPI_SQLT_RSET                               116
#define DPI_SQLT_NCO                                122
#define DPI_SQLT_ODT                                156
#define DPI_SQLT_DATE                               184
#define DPI_SQLT_TIMESTAMP                          187
#define DPI_SQLT_TIMESTAMP_TZ                       188
#define DPI_SQLT_INTERVAL_YM                        189
#define DPI_SQLT_INTERVAL_DS                        190
#define DPI_SQLT_TIMESTAMP_LTZ                      232
#define DPI_OCI_TYPECODE_SMALLINT                   246
#define DPI_SQLT_REC                                250
#define DPI_SQLT_BOL                                252

// define session pool constants
#define DPI_OCI_SPD_FORCE                           0x0001
#define DPI_OCI_SPC_HOMOGENEOUS                     0x0002
#define DPI_OCI_SPC_STMTCACHE                       0x0004

// define OCI session pool get constants
#define DPI_OCI_SESSGET_SPOOL                       0x0001
#define DPI_OCI_SESSGET_STMTCACHE                   0x0004
#define DPI_OCI_SESSGET_CREDPROXY                   0x0008
#define DPI_OCI_SESSGET_CREDEXT                     0x0010
#define DPI_OCI_SESSGET_SPOOL_MATCHANY              0x0020
#define DPI_OCI_SESSGET_SYSDBA                      0x0100

// define OCI authentication constants
#define DPI_OCI_CPW_SYSDBA                          0x00000010
#define DPI_OCI_CPW_SYSOPER                         0x00000020
#define DPI_OCI_CPW_SYSASM                          0x00800040
#define DPI_OCI_CPW_SYSBKP                          0x00000080
#define DPI_OCI_CPW_SYSDGD                          0x00000100
#define DPI_OCI_CPW_SYSKMT                          0x00000200

// define NLS constants
#define DPI_OCI_NLS_CS_IANA_TO_ORA                  0
#define DPI_OCI_NLS_CS_ORA_TO_IANA                  1
#define DPI_OCI_NLS_CHARSET_MAXBYTESZ               91
#define DPI_OCI_NLS_CHARSET_ID                      93
#define DPI_OCI_NLS_NCHARSET_ID                     94
#define DPI_OCI_NLS_MAXBUFSZ                        100
#define DPI_SQLCS_IMPLICIT                          1
#define DPI_SQLCS_NCHAR                             2

// define XA constants
#define DPI_XA_MAXGTRIDSIZE                         64
#define DPI_XA_MAXBQUALSIZE                         64
#define DPI_XA_XIDDATASIZE                          128

// define null indicator values
#define DPI_OCI_IND_NULL                            -1
#define DPI_OCI_IND_NOTNULL                         0

// define subscription QOS values
#define DPI_OCI_SUBSCR_QOS_RELIABLE                 0x01
#define DPI_OCI_SUBSCR_QOS_PURGE_ON_NTFN            0x10
#define DPI_OCI_SUBSCR_CQ_QOS_QUERY                 0x01
#define DPI_OCI_SUBSCR_CQ_QOS_BEST_EFFORT           0x02

// define miscellaneous OCI constants
#define DPI_OCI_CONTINUE                            -24200
#define DPI_OCI_INVALID_HANDLE                      -2
#define DPI_OCI_ERROR                               -1
#define DPI_OCI_DEFAULT                             0
#define DPI_OCI_SUCCESS                             0
#define DPI_OCI_ONE_PIECE                           0
#define DPI_OCI_ATTR_PURITY_DEFAULT                 0
#define DPI_OCI_NUMBER_UNSIGNED                     0
#define DPI_OCI_SUCCESS_WITH_INFO                   1
#define DPI_OCI_NTV_SYNTAX                          1
#define DPI_OCI_MEMORY_CLEARED                      1
#define DPI_OCI_SESSRLS_DROPSESS                    1
#define DPI_OCI_SERVER_NORMAL                       1
#define DPI_OCI_TYPEGET_ALL                         1
#define DPI_OCI_TRANS_NEW                           1
#define DPI_OCI_LOCK_NONE                           1
#define DPI_OCI_TEMP_BLOB                           1
#define DPI_OCI_CRED_RDBMS                          1
#define DPI_OCI_LOB_READONLY                        1
#define DPI_OCI_TEMP_CLOB                           2
#define DPI_OCI_CRED_EXT                            2
#define DPI_OCI_LOB_READWRITE                       2
#define DPI_OCI_DATA_AT_EXEC                        2
#define DPI_OCI_DYNAMIC_FETCH                       2
#define DPI_OCI_NUMBER_SIGNED                       2
#define DPI_OCI_PIN_ANY                             3
#define DPI_OCI_PTYPE_TYPE                          6
#define DPI_OCI_AUTH                                8
#define DPI_OCI_DURATION_SESSION                    10
#define DPI_OCI_NUMBER_SIZE                         22
#define DPI_OCI_NO_DATA                             100
#define DPI_OCI_STRLS_CACHE_DELETE                  0x0010
#define DPI_OCI_THREADED                            0x00000001
#define DPI_OCI_OBJECT                              0x00000002
#define DPI_OCI_STMT_SCROLLABLE_READONLY            0x00000008
#define DPI_OCI_STMT_CACHE                          0x00000040
#define DPI_OCI_TRANS_TWOPHASE                      0x01000000

//-----------------------------------------------------------------------------
// Macros
//-----------------------------------------------------------------------------
#define DPI_CHECK_PTR_NOT_NULL(handle, parameter) \
    if (!parameter) { \
        dpiError__set(&error, "check parameter " #parameter, \
                DPI_ERR_NULL_POINTER_PARAMETER, #parameter); \
        return dpiGen__endPublicFn(handle, DPI_FAILURE, &error); \
    }

#define DPI_CHECK_PTR_AND_LENGTH(handle, parameter) \
    if (!parameter && parameter ## Length > 0) { \
        dpiError__set(&error, "check parameter " #parameter, \
                DPI_ERR_PTR_LENGTH_MISMATCH, #parameter); \
        return dpiGen__endPublicFn(handle, DPI_FAILURE, &error); \
    }


//-----------------------------------------------------------------------------
// Enumerations
//-----------------------------------------------------------------------------

// error numbers
typedef enum {
    DPI_ERR_NO_ERR = 1000,
    DPI_ERR_NO_MEMORY,
    DPI_ERR_INVALID_HANDLE,
    DPI_ERR_ERR_NOT_INITIALIZED,
    DPI_ERR_GET_FAILED,
    DPI_ERR_CREATE_ENV,
    DPI_ERR_CONVERT_TEXT,
    DPI_ERR_QUERY_NOT_EXECUTED,
    DPI_ERR_UNHANDLED_DATA_TYPE,
    DPI_ERR_INVALID_ARRAY_POSITION,
    DPI_ERR_NOT_CONNECTED,
    DPI_ERR_CONN_NOT_IN_POOL,
    DPI_ERR_INVALID_PROXY,
    DPI_ERR_NOT_SUPPORTED,
    DPI_ERR_UNHANDLED_CONVERSION,
    DPI_ERR_ARRAY_SIZE_TOO_BIG,
    DPI_ERR_INVALID_DATE,
    DPI_ERR_VALUE_IS_NULL,
    DPI_ERR_ARRAY_SIZE_TOO_SMALL,
    DPI_ERR_BUFFER_SIZE_TOO_SMALL,
    DPI_ERR_VERSION_NOT_SUPPORTED,
    DPI_ERR_INVALID_ORACLE_TYPE,
    DPI_ERR_WRONG_ATTR,
    DPI_ERR_NOT_COLLECTION,
    DPI_ERR_INVALID_INDEX,
    DPI_ERR_NO_OBJECT_TYPE,
    DPI_ERR_INVALID_CHARSET,
    DPI_ERR_SCROLL_OUT_OF_RS,
    DPI_ERR_QUERY_POSITION_INVALID,
    DPI_ERR_NO_ROW_FETCHED,
    DPI_ERR_TLS_ERROR,
    DPI_ERR_ARRAY_SIZE_ZERO,
    DPI_ERR_EXT_AUTH_WITH_CREDENTIALS,
    DPI_ERR_CANNOT_GET_ROW_OFFSET,
    DPI_ERR_CONN_IS_EXTERNAL,
    DPI_ERR_TRANS_ID_TOO_LARGE,
    DPI_ERR_BRANCH_ID_TOO_LARGE,
    DPI_ERR_COLUMN_FETCH,
    DPI_ERR_STMT_CLOSED,
    DPI_ERR_LOB_CLOSED,
    DPI_ERR_INVALID_CHARSET_ID,
    DPI_ERR_INVALID_OCI_NUMBER,
    DPI_ERR_INVALID_NUMBER,
    DPI_ERR_NUMBER_TOO_LARGE,
    DPI_ERR_NUMBER_STRING_TOO_LONG,
    DPI_ERR_NULL_POINTER_PARAMETER,
    DPI_ERR_LOAD_LIBRARY,
    DPI_ERR_LOAD_SYMBOL,
    DPI_ERR_LIBRARY_TOO_OLD,
    DPI_ERR_NLS_ENV_VAR_GET,
    DPI_ERR_PTR_LENGTH_MISMATCH,
    DPI_ERR_NAN,
    DPI_ERR_WRONG_TYPE,
    DPI_ERR_BUFFER_SIZE_TOO_LARGE,
    DPI_ERR_NO_EDITION_WITH_CONN_CLASS,
    DPI_ERR_NO_BIND_VARS_IN_DDL,
    DPI_ERR_SUBSCR_CLOSED,
    DPI_ERR_NO_EDITION_WITH_NEW_PASSWORD,
    DPI_ERR_UNEXPECTED_OCI_RETURN_VALUE,
    DPI_ERR_MAX
} dpiErrorNum;

// handle types
typedef enum {
    DPI_HTYPE_NONE = 4000,
    DPI_HTYPE_CONN,
    DPI_HTYPE_POOL,
    DPI_HTYPE_STMT,
    DPI_HTYPE_VAR,
    DPI_HTYPE_LOB,
    DPI_HTYPE_OBJECT,
    DPI_HTYPE_OBJECT_TYPE,
    DPI_HTYPE_OBJECT_ATTR,
    DPI_HTYPE_SUBSCR,
    DPI_HTYPE_DEQ_OPTIONS,
    DPI_HTYPE_ENQ_OPTIONS,
    DPI_HTYPE_MSG_PROPS,
    DPI_HTYPE_ROWID,
    DPI_HTYPE_CONTEXT,
    DPI_HTYPE_MAX
} dpiHandleTypeNum;


//-----------------------------------------------------------------------------
// Mutex definitions
//-----------------------------------------------------------------------------
#ifdef _WIN32
    typedef CRITICAL_SECTION dpiMutexType;
    #define dpiMutex__initialize(m)     InitializeCriticalSection(&m)
    #define dpiMutex__destroy(m)        DeleteCriticalSection(&m)
    #define dpiMutex__acquire(m)        EnterCriticalSection(&m)
    #define dpiMutex__release(m)        LeaveCriticalSection(&m)
#else
    typedef pthread_mutex_t dpiMutexType;
    #define dpiMutex__initialize(m)     pthread_mutex_init(&m, NULL)
    #define dpiMutex__destroy(m)        pthread_mutex_destroy(&m)
    #define dpiMutex__acquire(m)        pthread_mutex_lock(&m)
    #define dpiMutex__release(m)        pthread_mutex_unlock(&m)
#endif


//-----------------------------------------------------------------------------
// old type definitions (to be dropped)
//-----------------------------------------------------------------------------

// structure used for creating connections (2.0)
typedef struct {
    dpiAuthMode authMode;
    const char *connectionClass;
    uint32_t connectionClassLength;
    dpiPurity purity;
    const char *newPassword;
    uint32_t newPasswordLength;
    dpiAppContext *appContext;
    uint32_t numAppContext;
    int externalAuth;
    void *externalHandle;
    dpiPool *pool;
    const char *tag;
    uint32_t tagLength;
    int matchAnyTag;
    const char *outTag;
    uint32_t outTagLength;
    int outTagFound;
} dpiConnCreateParams__v20;


//-----------------------------------------------------------------------------
// OCI type definitions
//-----------------------------------------------------------------------------
typedef struct {
    unsigned char value[DPI_OCI_NUMBER_SIZE];
} dpiOciNumber;

typedef struct {
    int16_t year;
    uint8_t month;
    uint8_t day;
    uint8_t hour;
    uint8_t minute;
    uint8_t second;
} dpiOciDate;

typedef struct {
    long formatID;
    long gtrid_length;
    long bqual_length;
    char data[DPI_XA_XIDDATASIZE];
} dpiOciXID;


//-----------------------------------------------------------------------------
// Internal implementation type definitions
//-----------------------------------------------------------------------------
typedef struct {
    void **handles;
    uint32_t numSlots;
    uint32_t numUsedSlots;
    uint32_t currentPos;
    dpiMutexType mutex;
} dpiHandleList;

typedef struct {
    void **handles;
    uint32_t numSlots;
    uint32_t numUsedSlots;
    uint32_t acquirePos;
    uint32_t releasePos;
    dpiMutexType mutex;
} dpiHandlePool;

typedef struct {
    int32_t code;
    uint16_t offset;
    dpiErrorNum errorNum;
    const char *fnName;
    const char *action;
    char encoding[DPI_OCI_NLS_MAXBUFSZ];
    char message[DPI_MAX_ERROR_SIZE];
    uint32_t messageLength;
    int isRecoverable;
} dpiErrorBuffer;

typedef struct {
    const dpiContext *context;
    void *handle;
    dpiMutexType mutex;
    char encoding[DPI_OCI_NLS_MAXBUFSZ];
    int32_t maxBytesPerCharacter;
    uint16_t charsetId;
    char nencoding[DPI_OCI_NLS_MAXBUFSZ];
    int32_t nmaxBytesPerCharacter;
    uint16_t ncharsetId;
    dpiHandlePool *errorHandles;
    dpiVersionInfo *versionInfo;
    void *baseDate;
    int threaded;
} dpiEnv;

typedef struct {
    dpiErrorBuffer *buffer;
    void *handle;
    dpiEnv *env;
} dpiError;

typedef void (*dpiTypeFreeProc)(void*, dpiError*);

typedef struct {
    const char *name;
    size_t size;
    uint32_t checkInt;
    dpiTypeFreeProc freeProc;
} dpiTypeDef;

#define dpiType_HEAD \
    const dpiTypeDef *typeDef; \
    uint32_t checkInt; \
    unsigned refCount; \
    dpiEnv *env;

typedef struct {
    dpiType_HEAD
} dpiBaseType;

typedef struct dpiOracleType {
    dpiOracleTypeNum oracleTypeNum;
    dpiNativeTypeNum defaultNativeTypeNum;
    uint16_t oracleType;
    uint8_t charsetForm;
    uint32_t sizeInBytes;
    int isCharacterData;
    int canBeInArray;
    int requiresPreFetch;
} dpiOracleType;

typedef struct {
    char *ptr;
    uint32_t length;
    uint32_t allocatedLength;
} dpiDynamicBytesChunk;

typedef struct {
    uint32_t numChunks;
    uint32_t allocatedChunks;
    dpiDynamicBytesChunk *chunks;
} dpiDynamicBytes;

typedef struct {
    dpiVar *var;
    uint32_t pos;
    const char *name;
    uint32_t nameLength;
} dpiBindVar;

typedef union {
    void *asHandle;
    dpiObject *asObject;
    dpiStmt *asStmt;
    dpiLob *asLOB;
    dpiRowid *asRowid;
} dpiReferenceBuffer;

typedef union {
    void *asRaw;
    char *asBytes;
    float *asFloat;
    double *asDouble;
    int64_t *asInt64;
    uint64_t *asUint64;
    dpiOciNumber *asNumber;
    dpiOciDate *asDate;
    void **asTimestamp;
    void **asInterval;
    void **asLobLocator;
    void **asString;
    void **asStmt;
    void **asRowid;
    int *asBoolean;
    void **asObject;
    void **asCollection;
} dpiOracleData;

typedef union {
    int64_t asInt64;
    uint64_t asUint64;
    float asFloat;
    double asDouble;
    dpiOciNumber asNumber;
    dpiOciDate asDate;
    int asBoolean;
    void *asString;
    void *asTimestamp;
    void *asLobLocator;
    void *asRaw;
} dpiOracleDataBuffer;

typedef struct {
    uint32_t maxArraySize;
    uint32_t actualArraySize;
    int16_t *indicator;
    uint16_t *returnCode;
    uint16_t *actualLength16;
    uint32_t *actualLength32;
    void **objectIndicator;
    dpiReferenceBuffer *references;
    dpiDynamicBytes *dynamicBytes;
    char *tempBuffer;
    dpiData *externalData;
    dpiOracleData data;
} dpiVarBuffer;


//-----------------------------------------------------------------------------
// External implementation type definitions
//-----------------------------------------------------------------------------
struct dpiPool {
    dpiType_HEAD
    void *handle;
    const char *name;
    uint32_t nameLength;
    int pingInterval;
    int pingTimeout;
    int homogeneous;
    int externalAuth;
};

struct dpiConn {
    dpiType_HEAD
    dpiPool *pool;
    void *handle;
    void *serverHandle;
    void *sessionHandle;
    const char *releaseString;
    uint32_t releaseStringLength;
    dpiVersionInfo versionInfo;
    uint32_t commitMode;
    uint16_t charsetId;
    dpiHandleList *openStmts;
    dpiHandleList *openLobs;
    int externalHandle;
    int deadSession;
    int standalone;
    int closing;
};

struct dpiContext {
    dpiType_HEAD
    dpiVersionInfo *versionInfo;
    uint8_t dpiMinorVersion;
};

struct dpiStmt {
    dpiType_HEAD
    dpiConn *conn;
    uint32_t openSlotNum;
    void *handle;
    uint32_t fetchArraySize;
    uint32_t bufferRowCount;
    uint32_t bufferRowIndex;
    uint32_t numQueryVars;
    dpiVar **queryVars;
    dpiQueryInfo *queryInfo;
    uint32_t allocatedBindVars;
    uint32_t numBindVars;
    dpiBindVar *bindVars;
    uint32_t numBatchErrors;
    dpiErrorBuffer *batchErrors;
    uint64_t rowCount;
    uint64_t bufferMinRow;
    uint16_t statementType;
    int isOwned;
    int hasRowsToFetch;
    int scrollable;
    int isReturning;
    int deleteFromCache;
    int closing;
};

struct dpiVar {
    dpiType_HEAD
    dpiConn *conn;
    const dpiOracleType *type;
    dpiNativeTypeNum nativeTypeNum;
    int requiresPreFetch;
    int isArray;
    uint32_t sizeInBytes;
    int isDynamic;
    dpiObjectType *objectType;
    dpiVarBuffer buffer;
    dpiVarBuffer *dynBindBuffers;
    dpiError *error;
};

struct dpiLob {
    dpiType_HEAD
    dpiConn *conn;
    uint32_t openSlotNum;
    const dpiOracleType *type;
    void *locator;
    char *buffer;
    int closing;
};

struct dpiObjectAttr {
    dpiType_HEAD
    dpiObjectType *belongsToType;
    const char *name;
    uint32_t nameLength;
    dpiDataTypeInfo typeInfo;
};

struct dpiObjectType {
    dpiType_HEAD
    dpiConn *conn;
    void *tdo;
    uint16_t typeCode;
    const char *schema;
    uint32_t schemaLength;
    const char *name;
    uint32_t nameLength;
    dpiDataTypeInfo elementTypeInfo;
    int isCollection;
    uint16_t numAttributes;
};

struct dpiObject {
    dpiType_HEAD
    dpiObjectType *type;
    void *instance;
    void *indicator;
    dpiObject *dependsOnObj;
    int freeIndicator;
};

struct dpiRowid {
    dpiType_HEAD
    void *handle;
    char *buffer;
    uint16_t bufferLength;
};

struct dpiSubscr {
    dpiType_HEAD
    dpiConn *conn;
    void *handle;
    dpiSubscrQOS qos;
    dpiSubscrCallback callback;
    void *callbackContext;
};

struct dpiDeqOptions {
    dpiType_HEAD
    dpiConn *conn;
    void *handle;
};

struct dpiEnqOptions {
    dpiType_HEAD
    dpiConn *conn;
    void *handle;
};

struct dpiMsgProps {
    dpiType_HEAD
    dpiConn *conn;
    void *handle;
    char *buffer;
    uint32_t bufferLength;
};


//-----------------------------------------------------------------------------
// definition of internal dpiContext methods
//-----------------------------------------------------------------------------
void dpiContext__initCommonCreateParams(dpiCommonCreateParams *params);
void dpiContext__initConnCreateParams(const dpiContext *context,
        dpiConnCreateParams *params, size_t *structSize);
void dpiContext__initPoolCreateParams(dpiPoolCreateParams *params);
void dpiContext__initSubscrCreateParams(dpiSubscrCreateParams *params);


//-----------------------------------------------------------------------------
// definition of internal dpiDataBuffer methods
//-----------------------------------------------------------------------------
int dpiDataBuffer__fromOracleDate(dpiDataBuffer *data,
        dpiOciDate *oracleValue);
int dpiDataBuffer__fromOracleIntervalDS(dpiDataBuffer *data, dpiEnv *env,
        dpiError *error, void *oracleValue);
int dpiDataBuffer__fromOracleIntervalYM(dpiDataBuffer *data, dpiEnv *env,
        dpiError *error, void *oracleValue);
int dpiDataBuffer__fromOracleNumberAsDouble(dpiDataBuffer *data,
        dpiError *error, void *oracleValue);
int dpiDataBuffer__fromOracleNumberAsInteger(dpiDataBuffer *data,
        dpiError *error, void *oracleValue);
int dpiDataBuffer__fromOracleNumberAsText(dpiDataBuffer *data, dpiEnv *env,
        dpiError *error, void *oracleValue);
int dpiDataBuffer__fromOracleNumberAsUnsignedInteger(dpiDataBuffer *data,
        dpiError *error, void *oracleValue);
int dpiDataBuffer__fromOracleTimestamp(dpiDataBuffer *data, dpiEnv *env,
        dpiError *error, void *oracleValue, int withTZ);
int dpiDataBuffer__fromOracleTimestampAsDouble(dpiDataBuffer *data,
        dpiEnv *env, dpiError *error, void *oracleValue);
int dpiDataBuffer__toOracleDate(dpiDataBuffer *data, dpiOciDate *oracleValue);
int dpiDataBuffer__toOracleIntervalDS(dpiDataBuffer *data, dpiEnv *env,
        dpiError *error, void *oracleValue);
int dpiDataBuffer__toOracleIntervalYM(dpiDataBuffer *data, dpiEnv *env,
        dpiError *error, void *oracleValue);
int dpiDataBuffer__toOracleNumberFromDouble(dpiDataBuffer *data,
        dpiError *error, void *oracleValue);
int dpiDataBuffer__toOracleNumberFromInteger(dpiDataBuffer *data,
        dpiError *error, void *oracleValue);
int dpiDataBuffer__toOracleNumberFromText(dpiDataBuffer *data, dpiEnv *env,
        dpiError *error, void *oracleValue);
int dpiDataBuffer__toOracleNumberFromUnsignedInteger(dpiDataBuffer *data,
        dpiError *error, void *oracleValue);
int dpiDataBuffer__toOracleTimestamp(dpiDataBuffer *data, dpiEnv *env,
        dpiError *error, void *oracleValue, int withTZ);
int dpiDataBuffer__toOracleTimestampFromDouble(dpiDataBuffer *data,
        dpiEnv *env, dpiError *error, void *oracleValue);


//-----------------------------------------------------------------------------
// definition of internal dpiEnv methods
//-----------------------------------------------------------------------------
void dpiEnv__free(dpiEnv *env, dpiError *error);
int dpiEnv__init(dpiEnv *env, const dpiContext *context,
        const dpiCommonCreateParams *params, dpiError *error);
int dpiEnv__getEncodingInfo(dpiEnv *env, dpiEncodingInfo *info);
int dpiEnv__initError(dpiEnv *env, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiError methods
//-----------------------------------------------------------------------------
int dpiError__check(dpiError *error, int status, dpiConn *conn,
        const char *action);
int dpiError__getInfo(dpiError *error, dpiErrorInfo *info);
int dpiError__set(dpiError *error, const char *context, dpiErrorNum errorNum,
        ...);


//-----------------------------------------------------------------------------
// definition of internal dpiGen methods
//-----------------------------------------------------------------------------
int dpiGen__addRef(void *ptr, dpiHandleTypeNum typeNum, const char *fnName);
int dpiGen__allocate(dpiHandleTypeNum typeNum, dpiEnv *env, void **handle,
        dpiError *error);
int dpiGen__checkHandle(const void *ptr, dpiHandleTypeNum typeNum,
        const char *context, dpiError *error);
int dpiGen__endPublicFn(const void *ptr, int returnValue, dpiError *error);
int dpiGen__release(void *ptr, dpiHandleTypeNum typeNum, const char *fnName);
void dpiGen__setRefCount(void *ptr, dpiError *error, int increment);
int dpiGen__startPublicFn(const void *ptr, dpiHandleTypeNum typeNum,
        const char *fnName, int needErrorHandle, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiGlobal methods
//-----------------------------------------------------------------------------
int dpiGlobal__initError(const char *fnName, dpiError *error);
int dpiGlobal__lookupCharSet(const char *name, uint16_t *charsetId,
        dpiError *error);
int dpiGlobal__lookupEncoding(uint16_t charsetId, char *encoding,
        dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiOracleType methods
//-----------------------------------------------------------------------------
const dpiOracleType *dpiOracleType__getFromNum(dpiOracleTypeNum oracleTypeNum,
        dpiError *error);
int dpiOracleType__populateTypeInfo(dpiConn *conn, void *handle,
        uint32_t handleType, dpiDataTypeInfo *info, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiConn methods
//-----------------------------------------------------------------------------
int dpiConn__create(dpiConn *conn, const dpiContext *context,
        const char *userName, uint32_t userNameLength, const char *password,
        uint32_t passwordLength, const char *connectString,
        uint32_t connectStringLength, dpiPool *pool,
        const dpiCommonCreateParams *commonParams,
        dpiConnCreateParams *createParams, dpiError *error);
void dpiConn__free(dpiConn *conn, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiPool methods
//-----------------------------------------------------------------------------
int dpiPool__acquireConnection(dpiPool *pool, const char *userName,
        uint32_t userNameLength, const char *password, uint32_t passwordLength,
        dpiConnCreateParams *params, dpiConn **conn, dpiError *error);
void dpiPool__free(dpiPool *pool, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiStmt methods
//-----------------------------------------------------------------------------
int dpiStmt__allocate(dpiConn *conn, int scrollable, dpiStmt **stmt,
        dpiError *error);
int dpiStmt__close(dpiStmt *stmt, const char *tag, uint32_t tagLength,
        int propagateErrors, dpiError *error);
void dpiStmt__free(dpiStmt *stmt, dpiError *error);
int dpiStmt__init(dpiStmt *stmt, dpiError *error);
int dpiStmt__prepare(dpiStmt *stmt, const char *sql, uint32_t sqlLength,
        const char *tag, uint32_t tagLength, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiVar methods
//-----------------------------------------------------------------------------
int dpiVar__allocate(dpiConn *conn, dpiOracleTypeNum oracleTypeNum,
        dpiNativeTypeNum nativeTypeNum, uint32_t maxArraySize, uint32_t size,
        int sizeIsBytes, int isArray, dpiObjectType *objType, dpiVar **var,
        dpiData **data, dpiError *error);
int dpiVar__convertToLob(dpiVar *var, dpiError *error);
int dpiVar__copyData(dpiVar *var, uint32_t pos, dpiData *sourceData,
        dpiError *error);
int32_t dpiVar__defineCallback(dpiVar *var, void *defnp, uint32_t iter,
        void **bufpp, uint32_t **alenpp, uint8_t *piecep, void **indpp,
        uint16_t **rcodepp);
int dpiVar__extendedPreFetch(dpiVar *var, dpiVarBuffer *buffer,
        dpiError *error);
void dpiVar__free(dpiVar *var, dpiError *error);
int32_t dpiVar__inBindCallback(dpiVar *var, void *bindp, uint32_t iter,
        uint32_t index, void **bufpp, uint32_t *alenp, uint8_t *piecep,
        void **indpp);
int dpiVar__getValue(dpiVar *var, dpiVarBuffer *buffer, uint32_t pos,
        int inFetch, dpiError *error);
int dpiVar__setValue(dpiVar *var, dpiVarBuffer *buffer, uint32_t pos,
        dpiData *data, dpiError *error);
int32_t dpiVar__outBindCallback(dpiVar *var, void *bindp, uint32_t iter,
        uint32_t index, void **bufpp, uint32_t **alenpp, uint8_t *piecep,
        void **indpp, uint16_t **rcodepp);


//-----------------------------------------------------------------------------
// definition of internal dpiLob methods
//-----------------------------------------------------------------------------
int dpiLob__allocate(dpiConn *conn, const dpiOracleType *type, dpiLob **lob,
        dpiError *error);
int dpiLob__close(dpiLob *lob, int propagateErrors, dpiError *error);
void dpiLob__free(dpiLob *lob, dpiError *error);
int dpiLob__readBytes(dpiLob *lob, uint64_t offset, uint64_t amount,
        char *value, uint64_t *valueLength, dpiError *error);
int dpiLob__setFromBytes(dpiLob *lob, const char *value, uint64_t valueLength,
        dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiObject methods
//-----------------------------------------------------------------------------
int dpiObject__allocate(dpiObjectType *objType, void *instance,
        void *indicator, dpiObject *dependsOnObj, dpiObject **obj,
        dpiError *error);
void dpiObject__free(dpiObject *obj, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiObjectType methods
//-----------------------------------------------------------------------------
int dpiObjectType__allocate(dpiConn *conn, void *param,
        uint32_t nameAttribute, dpiObjectType **objType, dpiError *error);
void dpiObjectType__free(dpiObjectType *objType, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiObjectAttr methods
//-----------------------------------------------------------------------------
int dpiObjectAttr__allocate(dpiObjectType *objType, void *param,
        dpiObjectAttr **attr, dpiError *error);
int dpiObjectAttr__check(dpiObjectAttr *attr, dpiError *error);
void dpiObjectAttr__free(dpiObjectAttr *attr, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiRowid methods
//-----------------------------------------------------------------------------
int dpiRowid__allocate(dpiConn *conn, dpiRowid **rowid, dpiError *error);
void dpiRowid__free(dpiRowid *rowid, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiSubscr methods
//-----------------------------------------------------------------------------
void dpiSubscr__free(dpiSubscr *subscr, dpiError *error);
int dpiSubscr__create(dpiSubscr *subscr, dpiConn *conn,
        dpiSubscrCreateParams *params, uint64_t *subscrId, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiDeqOptions methods
//-----------------------------------------------------------------------------
int dpiDeqOptions__create(dpiDeqOptions *options, dpiConn *conn,
        dpiError *error);
void dpiDeqOptions__free(dpiDeqOptions *options, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiEnqOptions methods
//-----------------------------------------------------------------------------
int dpiEnqOptions__create(dpiEnqOptions *options, dpiConn *conn,
        dpiError *error);
void dpiEnqOptions__free(dpiEnqOptions *options, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiOci methods
//-----------------------------------------------------------------------------
int dpiOci__aqDeq(dpiConn *conn, const char *queueName, void *options,
        void *msgProps, void *payloadType, void **payload, void **payloadInd,
        void **msgId, dpiError *error);
int dpiOci__aqEnq(dpiConn *conn, const char *queueName, void *options,
        void *msgProps, void *payloadType, void **payload, void **payloadInd,
        void **msgId, dpiError *error);
int dpiOci__arrayDescriptorAlloc(void *envHandle, void **handle,
        uint32_t handleType, uint32_t arraySize, dpiError *error);
int dpiOci__arrayDescriptorFree(void **handle, uint32_t handleType);
int dpiOci__attrGet(const void *handle, uint32_t handleType, void *ptr,
        uint32_t *size, uint32_t attribute, const char *action,
        dpiError *error);
int dpiOci__attrSet(void *handle, uint32_t handleType, void *ptr,
        uint32_t size, uint32_t attribute, const char *action,
        dpiError *error);
int dpiOci__bindByName(dpiStmt *stmt, void **bindHandle, const char *name,
        int32_t nameLength, int dynamicBind, dpiVar *var, dpiError *error);
int dpiOci__bindByName2(dpiStmt *stmt, void **bindHandle, const char *name,
        int32_t nameLength, int dynamicBind, dpiVar *var, dpiError *error);
int dpiOci__bindByPos(dpiStmt *stmt, void **bindHandle, uint32_t pos,
        int dynamicBind, dpiVar *var, dpiError *error);
int dpiOci__bindByPos2(dpiStmt *stmt, void **bindHandle, uint32_t pos,
        int dynamicBind, dpiVar *var, dpiError *error);
int dpiOci__bindDynamic(dpiVar *var, void *bindHandle, dpiError *error);
int dpiOci__bindObject(dpiVar *var, void *bindHandle, dpiError *error);
int dpiOci__break(dpiConn *conn, dpiError *error);
void dpiOci__clientVersion(dpiContext *context);
int dpiOci__collAppend(dpiConn *conn, const void *elem, const void *elemInd,
        void *coll, dpiError *error);
int dpiOci__collAssignElem(dpiConn *conn, int32_t index, const void *elem,
        const void *elemInd, void *coll, dpiError *error);
int dpiOci__collGetElem(dpiConn *conn, void *coll, int32_t index, int *exists,
        void **elem, void **elemInd, dpiError *error);
int dpiOci__collSize(dpiConn *conn, void *coll, int32_t *size,
        dpiError *error);
int dpiOci__collTrim(dpiConn *conn, uint32_t numToTrim, void *coll,
        dpiError *error);
int dpiOci__contextGetValue(dpiConn *conn, const char *key, uint32_t keyLength,
        void **value, int checkError, dpiError *error);
int dpiOci__contextSetValue(dpiConn *conn, const char *key, uint32_t keyLength,
        void *value, int checkError, dpiError *error);
int dpiOci__dateTimeConstruct(void *envHandle, void *handle, int16_t year,
        uint8_t month, uint8_t day, uint8_t hour, uint8_t minute,
        uint8_t second, uint32_t fsecond, const char *tz, size_t tzLength,
        dpiError *error);
int dpiOci__dateTimeGetDate(void *envHandle, void *handle, int16_t *year,
        uint8_t *month, uint8_t *day, dpiError *error);
int dpiOci__dateTimeGetTime(void *envHandle, void *handle, uint8_t *hour,
        uint8_t *minute, uint8_t *second, uint32_t *fsecond, dpiError *error);
int dpiOci__dateTimeGetTimeZoneOffset(void *envHandle, void *handle,
        int8_t *tzHourOffset, int8_t *tzMinuteOffset, dpiError *error);
int dpiOci__dateTimeIntervalAdd(void *envHandle, void *handle, void *interval,
        void *outHandle, dpiError *error);
int dpiOci__dateTimeSubtract(void *envHandle, void *handle1, void *handle2,
        void *interval, dpiError *error);
int dpiOci__dbShutdown(dpiConn *conn, uint32_t mode, dpiError *error);
int dpiOci__dbStartup(dpiConn *conn, uint32_t mode, dpiError *error);
int dpiOci__defineByPos(dpiStmt *stmt, void **defineHandle, uint32_t pos,
        dpiVar *var, dpiError *error);
int dpiOci__defineByPos2(dpiStmt *stmt, void **defineHandle, uint32_t pos,
        dpiVar *var, dpiError *error);
int dpiOci__defineDynamic(dpiVar *var, void *defineHandle, dpiError *error);
int dpiOci__defineObject(dpiVar *var, void *defineHandle, dpiError *error);
int dpiOci__describeAny(dpiConn *conn, void *obj, uint32_t objLength,
        uint8_t objType, void *describeHandle, dpiError *error);
int dpiOci__descriptorAlloc(void *envHandle, void **handle,
        const uint32_t handleType, const char *action, dpiError *error);
int dpiOci__descriptorFree(void *handle, uint32_t handleType);
int dpiOci__envNlsCreate(void **envHandle, uint32_t mode, uint16_t charsetId,
        uint16_t ncharsetId, dpiError *error);
int dpiOci__errorGet(void *handle, uint32_t handleType, uint16_t charsetId,
        const char *action, dpiError *error);
int dpiOci__handleAlloc(void *envHandle, void **handle, uint32_t handleType,
        const char *action, dpiError *error);
int dpiOci__handleFree(void *handle, uint32_t handleType);
int dpiOci__intervalGetDaySecond(void *envHandle, int32_t *day, int32_t *hour,
        int32_t *minute, int32_t *second, int32_t *fsecond,
        const void *interval, dpiError *error);
int dpiOci__intervalGetYearMonth(void *envHandle, int32_t *year,
        int32_t *month, const void *interval, dpiError *error);
int dpiOci__intervalSetDaySecond(void *envHandle, int32_t day, int32_t hour,
        int32_t minute, int32_t second, int32_t fsecond, void *interval,
        dpiError *error);
int dpiOci__intervalSetYearMonth(void *envHandle, int32_t year, int32_t month,
        void *interval, dpiError *error);
int dpiOci__lobClose(dpiLob *lob, dpiError *error);
int dpiOci__lobCreateTemporary(dpiLob *lob, dpiError *error);
int dpiOci__lobFileExists(dpiLob *lob, int *exists, dpiError *error);
int dpiOci__lobFileGetName(dpiLob *lob, char *dirAlias,
        uint16_t *dirAliasLength, char *name, uint16_t *nameLength,
        dpiError *error);
int dpiOci__lobFileSetName(dpiLob *lob, const char *dirAlias,
        uint16_t dirAliasLength, const char *name, uint16_t nameLength,
        dpiError *error);
int dpiOci__lobFreeTemporary(dpiLob *lob, int checkError, dpiError *error);
int dpiOci__lobGetChunkSize(dpiLob *lob, uint32_t *size, dpiError *error);
int dpiOci__lobGetLength2(dpiLob *lob, uint64_t *size, dpiError *error);
int dpiOci__lobIsOpen(dpiLob *lob, int *isOpen, dpiError *error);
int dpiOci__lobIsTemporary(dpiLob *lob, int *isTemporary, int checkError,
        dpiError *error);
int dpiOci__lobLocatorAssign(dpiLob *lob, void **copiedHandle,
        dpiError *error);
int dpiOci__lobOpen(dpiLob *lob, dpiError *error);
int dpiOci__lobRead2(dpiLob *lob, uint64_t offset, uint64_t *amountInBytes,
        uint64_t *amountInChars, char *buffer, uint64_t bufferLength,
        dpiError *error);
int dpiOci__lobTrim2(dpiLob *lob, uint64_t newLength, dpiError *error);
int dpiOci__lobWrite2(dpiLob *lob, uint64_t offset, const char *value,
        uint64_t valueLength, dpiError *error);
int dpiOci__memoryAlloc(dpiConn *conn, void **ptr, uint32_t size,
        int checkError, dpiError *error);
int dpiOci__memoryFree(dpiConn *conn, void *ptr, dpiError *error);
int dpiOci__nlsCharSetConvert(void *envHandle, uint16_t destCharsetId,
        char *dest, size_t destLength, uint16_t sourceCharsetId,
        const char *source, size_t sourceLength, size_t *resultSize,
        dpiError *error);
int dpiOci__nlsCharSetIdToName(void *envHandle, char *buf, size_t bufLength,
        uint16_t charsetId, dpiError *error);
int dpiOci__nlsCharSetNameToId(void *envHandle, const char *name,
        uint16_t *charsetId, dpiError *error);
int dpiOci__nlsEnvironmentVariableGet(uint16_t item, void *value,
        dpiError *error);
int dpiOci__nlsNameMap(void *envHandle, char *buf, size_t bufLength,
        const char *source, uint32_t flag, dpiError *error);
int dpiOci__nlsNumericInfoGet(void *envHandle, int32_t *value, uint16_t item,
        dpiError *error);
int dpiOci__numberFromInt(const void *value, unsigned int valueLength,
        unsigned int flags, void *number, dpiError *error);
int dpiOci__numberFromReal(const double value, void *number, dpiError *error);
int dpiOci__numberToInt(void *number, void *value, unsigned int valueLength,
        unsigned int flags, dpiError *error);
int dpiOci__numberToReal(double *value, void *number, dpiError *error);
int dpiOci__objectCopy(dpiObject *obj, void *sourceInstance,
        void *sourceIndicator, dpiError *error);
int dpiOci__objectFree(dpiObject *obj, dpiError *error);
int dpiOci__objectGetAttr(dpiObject *obj, dpiObjectAttr *attr,
        int16_t *scalarValueIndicator, void **valueIndicator, void **value,
        void **tdo, dpiError *error);
int dpiOci__objectGetInd(dpiObject *obj, dpiError *error);
int dpiOci__objectNew(dpiObject *obj, dpiError *error);
int dpiOci__objectPin(void *envHandle, void *objRef, void **obj,
        dpiError *error);
int dpiOci__objectSetAttr(dpiObject *obj, dpiObjectAttr *attr,
        int16_t scalarValueIndicator, void *valueIndicator, const void *value,
        dpiError *error);
int dpiOci__paramGet(const void *handle, uint32_t handleType, void **parameter,
        uint32_t pos, const char *action, dpiError *error);
int dpiOci__passwordChange(dpiConn *conn, const char *userName,
        uint32_t userNameLength, const char *oldPassword,
        uint32_t oldPasswordLength, const char *newPassword,
        uint32_t newPasswordLength, uint32_t mode, dpiError *error);
int dpiOci__ping(dpiConn *conn, dpiError *error);
int dpiOci__rawAssignBytes(void *envHandle, const char *value,
        uint32_t valueLength, void **handle, dpiError *error);
int dpiOci__rawPtr(void *envHandle, void *handle, void **ptr);
int dpiOci__rawResize(void *envHandle, void **handle, uint32_t newSize,
        dpiError *error);
int dpiOci__rawSize(void *envHandle, void *handle, uint32_t *size);
int dpiOci__rowidToChar(dpiRowid *rowid, char *buffer, uint16_t *bufferSize,
        dpiError *error);
int dpiOci__serverAttach(dpiConn *conn, const char *connectString,
        uint32_t connectStringLength, dpiError *error);
int dpiOci__serverDetach(dpiConn *conn, int checkError, dpiError *error);
int dpiOci__serverRelease(dpiConn *conn, char *buffer, uint32_t bufferSize,
        uint32_t *version, dpiError *error);
int dpiOci__sessionBegin(dpiConn *conn, uint32_t credentialType,
        uint32_t mode, dpiError *error);
int dpiOci__sessionEnd(dpiConn *conn, int checkError, dpiError *error);
int dpiOci__sessionGet(void *envHandle, void **handle, void *authInfo,
        const char *connectString, uint32_t connectStringLength,
        const char *tag, uint32_t tagLength, const char **outTag,
        uint32_t *outTagLength, int *found, uint32_t mode, dpiError *error);
int dpiOci__sessionPoolCreate(dpiPool *pool, const char *connectString,
        uint32_t connectStringLength, uint32_t minSessions,
        uint32_t maxSessions, uint32_t sessionIncrement, const char *userName,
        uint32_t userNameLength, const char *password, uint32_t passwordLength,
        uint32_t mode, dpiError *error);
int dpiOci__sessionPoolDestroy(dpiPool *pool, uint32_t mode, int checkError,
        dpiError *error);
int dpiOci__sessionRelease(dpiConn *conn, const char *tag, uint32_t tagLength,
        uint32_t mode, int checkError, dpiError *error);
int dpiOci__shardingKeyColumnAdd(void *shardingKey, void *col, uint32_t colLen,
        uint16_t colType, dpiError *error);
int dpiOci__stmtExecute(dpiStmt *stmt, uint32_t numIters, uint32_t mode,
        dpiError *error);
int dpiOci__stmtFetch2(dpiStmt *stmt, uint32_t numRows, uint16_t fetchMode,
        int32_t offset, dpiError *error);
int dpiOci__stmtGetBindInfo(dpiStmt *stmt, uint32_t size, uint32_t startLoc,
        int32_t *numFound, char *names[], uint8_t nameLengths[],
        char *indNames[], uint8_t indNameLengths[], uint8_t isDuplicate[],
        void *bindHandles[], dpiError *error);
int dpiOci__stmtGetNextResult(dpiStmt *stmt, void **handle, dpiError *error);
int dpiOci__stmtPrepare2(dpiStmt *stmt, const char *sql, uint32_t sqlLength,
        const char *tag, uint32_t tagLength, dpiError *error);
int dpiOci__stmtRelease(dpiStmt *stmt, const char *tag, uint32_t tagLength,
        int checkError, dpiError *error);
int dpiOci__stringAssignText(void *envHandle, const char *value,
        uint32_t valueLength, void **handle, dpiError *error);
int dpiOci__stringPtr(void *envHandle, void *handle, char **ptr);
int dpiOci__stringResize(void *envHandle, void **handle, uint32_t newSize,
        dpiError *error);
int dpiOci__stringSize(void *envHandle, void *handle, uint32_t *size);
int dpiOci__subscriptionRegister(dpiConn *conn, void **handle,
        dpiError *error);
int dpiOci__subscriptionUnRegister(dpiSubscr *subscr, dpiError *error);
int dpiOci__tableDelete(dpiObject *obj, int32_t index, dpiError *error);
int dpiOci__tableExists(dpiObject *obj, int32_t index, int *exists,
        dpiError *error);
int dpiOci__tableFirst(dpiObject *obj, int32_t *index, dpiError *error);
int dpiOci__tableLast(dpiObject *obj, int32_t *index, dpiError *error);
int dpiOci__tableNext(dpiObject *obj, int32_t index, int32_t *nextIndex,
        int *exists, dpiError *error);
int dpiOci__tablePrev(dpiObject *obj, int32_t index, int32_t *prevIndex,
        int *exists, dpiError *error);
int dpiOci__tableSize(dpiObject *obj, int32_t *size, dpiError *error);
int dpiOci__threadKeyDestroy(void *envHandle, void *errorHandle, void **key,
        dpiError *error);
int dpiOci__threadKeyGet(void *envHandle, void *errorHandle, void *key,
        void **value, dpiError *error);
int dpiOci__threadKeyInit(void *envHandle, void *errorHandle, void **key,
        void *destroyFunc, dpiError *error);
int dpiOci__threadKeySet(void *envHandle, void *errorHandle, void *key,
        void *value, dpiError *error);
int dpiOci__transCommit(dpiConn *conn, uint32_t flags, dpiError *error);
int dpiOci__transPrepare(dpiConn *conn, int *commitNeeded, dpiError *error);
int dpiOci__transRollback(dpiConn *conn, int checkError, dpiError *error);
int dpiOci__transStart(dpiConn *conn, dpiError *error);
int dpiOci__typeByFullName(dpiConn *conn, const char *name,
        uint32_t nameLength, void **tdo, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiMsgProps methods
//-----------------------------------------------------------------------------
int dpiMsgProps__create(dpiMsgProps *props, dpiConn *conn, dpiError *error);
int dpiMsgProps__extractMsgId(dpiMsgProps *props, void *ociRaw,
        const char **msgId, uint32_t *msgIdLength, dpiError *error);
void dpiMsgProps__free(dpiMsgProps *props, dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiHandlePool methods
//-----------------------------------------------------------------------------
int dpiHandlePool__acquire(dpiHandlePool *pool, void **handle,
        dpiError *error);
int dpiHandlePool__create(dpiHandlePool **pool, dpiError *error);
void dpiHandlePool__free(dpiHandlePool *pool);
void dpiHandlePool__release(dpiHandlePool *pool, void *handle,
        dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiHandleList methods
//-----------------------------------------------------------------------------
int dpiHandleList__addHandle(dpiHandleList *list, void *handle,
        uint32_t *slotNum, dpiError *error);
int dpiHandleList__create(dpiHandleList **list, dpiError *error);
void dpiHandleList__free(dpiHandleList *list);
void dpiHandleList__removeHandle(dpiHandleList *list, uint32_t slotNum);


//-----------------------------------------------------------------------------
// definition of internal dpiUtils methods
//-----------------------------------------------------------------------------
int dpiUtils__allocateMemory(size_t numMembers, size_t memberSize,
        int clearMemory, const char *action, void **ptr, dpiError *error);
void dpiUtils__clearMemory(void *ptr, size_t length);
void dpiUtils__freeMemory(void *ptr);
int dpiUtils__getAttrStringWithDup(const char *action, const void *ociHandle,
        uint32_t ociHandleType, uint32_t ociAttribute, const char **value,
        uint32_t *valueLength, dpiError *error);
int dpiUtils__parseNumberString(const char *value, uint32_t valueLength,
        uint16_t charsetId, int *isNegative, int16_t *decimalPointIndex,
        uint8_t *numDigits, uint8_t *digits, dpiError *error);
int dpiUtils__parseOracleNumber(void *oracleValue, int *isNegative,
        int16_t *decimalPointIndex, uint8_t *numDigits, uint8_t *digits,
        dpiError *error);
int dpiUtils__setAttributesFromCommonCreateParams(void *handle,
        uint32_t handleType, const dpiCommonCreateParams *params,
        dpiError *error);


//-----------------------------------------------------------------------------
// definition of internal dpiDebug methods
//-----------------------------------------------------------------------------
void dpiDebug__initialize(void);
void dpiDebug__print(const char *format, ...);

#endif

