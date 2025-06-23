# Copyright (c) 2022, 2025, Oracle. All rights reserved.
# Makefile for Oracle Call Interface examples
# Christopher Jones, 2022
# Sharad Chandran R, 2025

IC=$(HOME)/instantclient_19_26
OLIB=$(IC)
OINC=$(IC)/sdk/include
DEMOS=drcpDemo simpleConnDemo sessionPoolingDemo 

#OH=/u01/app/oracle/product/19.26.0/dbhome_1
#OLIB=$(OH)/lib
#OINC=$(OH)/rdbms/public

$(DEMOS): clean
	$(CC) -Wall -Wextra -c -I$(OINC) $@.c
	$(CC) -o $@ $@.o -Wl,--rpath -Wl,$(OLIB) -L$(OLIB) -lclntsh

clean: $(DEMOS)
	rm -f $(DEMOS) *.o
