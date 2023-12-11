testcase for SVM using research abstracts
------------------------------------------

1. create_user.sql
---- all other steps run as test account
2. create_tables.sql
3. load_all.sh
4. setup_svm.sql
5. match.sql


When the last step is run, it produces the following incorrect output - the CAT_NAME for __all__ abstracts should be 'Brain':

     DOCID CAT_NAME        MATCH_SCORE
---------- --------------- -----------
       278 Brain                    82
       279 Brain                    82
       280 Brain                    54
       281 Brain                    66
       282 Brain                    81
       283 Brain                    81
       284 Brain                    87
       285 Brain                    73
       286 Brain                    81
       287 Brain                    81
       288 Brain                    81
       289 Brain                    38
       290 Brain                    36
       291 Brain                    78
       292 Brain                    70
       293 Microbes                 47
       294 Brain                    48
       295 Brain                    70
       296 Brain                    74
       297 Brain                    81
       298 Brain                    81
       299 Brain                    81
       300 Brain                    81
       301 Brain                    89
       302 Brain                    44
       303 Brain                    40
       304 Cancer                   46
       305 Brain                    81
       306 Brain                    81
       307 Brain                    62
       308 Brain                    78
       309 Brain                    81
       310 Brain                    81
       311 Brain                    35
       312 Brain                    90
       313 Brain                    40
       314 Brain                    29
       315 Brain                    63
       316 Brain                    62
       317 Brain                    76
       318 Brain                    79
       319 Brain                    39
       320 Brain                    81
       321 Brain                    71
       322 Brain                    71
       323 Brain                    84
       324 Brain                    81
       325 Brain                    81
       326 Brain                    38
       327 Brain                    81
       328 Brain                    46
       329 Brain                    87
       330 Brain                    35
       330 Cancer                   35
       331 Brain                    81
       332 Brain                    81
       333 Brain                    95
       334 Brain                    81
       335 Brain                    78
       336 Brain                    55
       337 Brain                    47
       338 Brain                    93
       339 Brain                    93
       340 Brain                    70
       341 Brain                    70
       342 Brain                    87
       343 Brain                    81

67 rows selected.
