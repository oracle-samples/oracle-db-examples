IC=$(HOME)/instantclient_19_11
OLIB=$(IC)
OINC=$(IC)/sdk/include

#OH=/u01/app/oracle/product/12.1.0/dbhome_1
#OLIB=$(OH)/lib
#OINC=$(OH)/rdbms/public

drcp: clean
	$(CC) -Wall -Wextra -c -I$(OINC) drcp.c
	$(CC) -o drcp drcp.o -Wl,--rpath -Wl,$(OLIB) -L$(OLIB) -lclntsh

clean:
	rm -f drcp.o drcp
