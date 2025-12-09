###############################################################################
#                       Make file for PROC demos
###############################################################################
#  Usage :
# For compiling proc demos
#    make -f makefile_proc.mk
#
# For precompiling, compiling & linking the procdemo.pc file
#    make -f makefile_proc.mk build EXE=procdemo OBJS=procdemo.o
#
# In general, for any proc program
#    make -f makefile_proc.mk build EXE=<exename> OBJS="<list of dependent objs>"
#
#    To make use of any PROC options during precompilation, 
#        make -f makefile_proc.mk build PROCFLAGS="<list of proc options>" 
#            EXE=<exename> OBJS="<list of dependent objs>"
#
# NOTES: 
#    1. Please change "cc/CC" and the "InstantClient directories" to point to 
#       appropiate locations on your machine before using this makefile.
#    2. In case of RPM installation, please change the following variables
#       as mentioned below:
#         PROC=/usr/lib/oracle/VV.v/client/bin/proc
#         CCINCLUDES=$(I_SYM)/usr/include/oracle/VV.v/client
#         PRECOMPPUBH=/usr/include/oracle/VV.v/client
#         ICLIBHOME=/usr/lib/oracle/VV.v/client/lib/
#       Legend:
#         VV - Major Oracle version number
#          v - Minor Oracle version number
#         (Ex:  For the release 11.2, VV = 11 and v = 2)
#
###############################################################################


CC=/usr/bin/gcc
cc=/usr/bin/gcc

# InstantClient Directories.
ICSDKHOME=../
ICLIBHOME=../../

MKLINK=ln
REMOVE=rm -rf
CLNCACHE=cleancache
CACHEDIR=SunWS_cachea
MAKE=make
MAKEFILE=makefile_proc.mk
PROCDEMO=procdemo

PROC=$(ICSDKHOME)/proc
SO_EXT=.so
I_SYM=-I

CCINCLUDES= $(I_SYM)$(ICSDKHOME)/include

# Pre-compiler Flags.
PRECOMPPUBH=$(ICSDKHOME)include

# Compiler Flags.
OPTIMIZE=-O2
LDPATHFLAG=-L
SPFLAGS=-DLINUX -D_GNU_SOURCE -D_LARGEFILE64_SOURCE=1 -D_LARGEFILE_SOURCE=1 -DSLTS_ENABLE -DSLMXMX_ENABLE -D_REENTRANT -DNS_THREADS
CCFLAGS= -fPIC -DPRECOMP
LDFLAGS=-g
LPFLAGS=
GFLAG=
CDEBUG=
USRFLAGS=
ICLIBPATH=$(LDPATHFLAG)$(ICLIBHOME)
PFLAGS=$(CCINCLUDES) $(SPFLAGS) $(LPFLAGS)
CFLAGS=$(GFLAG) $(OPTIMIZE) $(CDEBUG) $(CCFLAGS) $(PFLAGS) $(USRFLAGS)

# Libraries.
PROLDLIBS=$(LDCLIENTLIBS) $(THREADLIBS)
LDCLIENTLIBS=$(ICLIBPATH) $(LLIBCLNTSH) $(LDLIBS)
LLIBCLNTSH=$(LDLIBFLAG)$(LIBCLNTSHNAME)
LDLIBFLAG=-l
LIBCLNTCORENAME=clntshcore
LIBCLNTSHNAME=clntsh
LDLIBS=$(EXSYSLIBS) $(MATHLIB) $(USRLIBS)
EXSYSLIBS=-ldl
MATHLIB=-lm
THREADLIBS=-lpthread

C2O=$(CC) $(CFLAGS) -c $*.c
PCC2C=$(PROC) $(PROCFLAGS) iname=$(PCCSRC)
DEMO_PROC_BUILD=$(CC) -o $(EXE) $(OBJS) $(LDFLAGS) $(PROLDLIBS)

#-----------------------------------------------------------------------------
# Targets for building the proc sample programs.
all: clean $(PROCDEMO)

$(PROCDEMO):
	$(MAKE) -f $(MAKEFILE) build OBJS=$@.o EXE=$@
	
build: $(CLNCACHE) $(OBJS)
	$(DEMO_PROC_BUILD)

#-----------------------------------------------------------------------------
# Here are some rules for converting .pc -> .c -> .o
.SUFFIXES: .pc .c .o

pc1:
	$(PCC2C)

.pc.c:
	$(MAKE) -f $(MAKEFILE) PROCFLAGS="$(PROCFLAGS)" PCCSRC=$* I_SYM=include= pc1

.pc.o:
	$(MAKE) -f $(MAKEFILE) PROCFLAGS="$(PROCFLAGS)" PCCSRC=$* I_SYM=include= pc1
	$(C2O)

.c.o:
	$(C2O)

#-----------------------------------------------------------------------------
# Clean up all executables, *.o and generated *.c files
clean: $(CLNCACHE)
	$(REMOVE) $(PROCDEMO) $(PROCDEMO).o $(PROCDEMO).c $(PROCDEMO).lis

cleancache:
	$(REMOVE) $(CACHEDIR)

