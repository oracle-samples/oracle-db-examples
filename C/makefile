# Copyright (c) 2022, 2025, Oracle. All rights reserved.
# Makefile for Oracle Call Interface examples
# Christopher Jones, 2022
# Sharad Chandran R, 2025

# Update the instant client path here
IC=$(HOME)/instantclient_19_26
OLIB=$(IC)
OINC=$(IC)/sdk/include
DEMOS=drcpDemo simpleConnDemo sessionPoolingDemo

# Uncomment the following 3 lines if you are using an
# Oracle Database home
#OH=/u01/app/oracle/product/19.26.0/dbhome_1
#OLIB=$(OH)/lib
#OINC=$(OH)/rdbms/public

.PHONY: all clean

all: $(DEMOS)

$(DEMOS): %: %.c
	$(CC) -Wall -Wextra -c -I$(OINC) $<
	$(CC) -o $@ $@.o -Wl,--rpath -Wl,$(OLIB) -L$(OLIB) -lclntsh

clean:
	rm -f $(DEMOS) *.o
