#########################################################
# oml4spark_function_zeppelin_visualization_z_show.r
#
# Function to help publish graphically in Apache Zeppelin and   
# Big Data Manager Notebooks several different types of  
# input, including R dataframes, OML4Spark DFS ID (HDFS),    
# HIVE tables, IMPALA tables and Spark Dataframes mapped 
# via OML4Spark 2.8.x algorithms or orch.df.* functions      
#                                                        
# Usage: z.show( data , # of records )                 
#                                                        
# If number of records is not specified we take a sample 
# of 1,000 observations or return the original number
# of records (if smaller) 
#                                                        
# Copyright (c) 2020 Oracle Corporation                        
# The Universal Permissive License (UPL), Version 1.0          
#                                                              
# https://oss.oracle.com/licenses/upl/                         
#                                          
##########################################################

z.show <- function(dat,n=1000){
  eachRowPrint <- function(x) paste0(paste(x,collapse="\t"),"\n")
  # Verify if OML4Spark packages are loaded
  if ("ORCH" %in% (.packages())) {
    # For Spark DF
    if ((spark.connected()) && (class(dat)[1]=="jobjRef")) {
      tot <- dat$count()
      prop <- min(n,tot)/tot
      tmp <- dat$sample( FALSE , prop )
      final <- head(orch.df.collect(tmp),n)
      cols <- paste0(paste(unlist(colnames(final)),collapse="\t"),"\n")
      rows <- apply(final,1,FUN=eachRowPrint)
      return(paste0("%table ",cols,paste0(rows, sep="",collapse = "")))
    } else
      # For HDFS
      # Check if the input if a DFS ID (HDFS)
      if (is.hdfs.id(dat)) {
        n <- min(n,hdfs.nrow(dat))
        tmp <- read.csv(text=hdfs.head(dat,n),header=FALSE)
        names(tmp) <- unlist(strsplit(hdfs.describe(dat)[5,2],','))
        final <- tmp
        rm(tmp)
        cols <- paste0(paste(unlist(colnames(final)),collapse="\t"),"\n")
        rows <- apply(final,1,FUN=eachRowPrint)
        return(paste0("%table ",cols,paste0(rows, sep="",collapse = "")))
      } else
        # Check if the input is HIVE
        if ( ore.is.connected(type='HIVE') && (is.ore.frame(dat)) ) {
          tot <- nrow(dat)
          n <- min(n,tot)
          prop <- min(1, (n/tot * 2))
          # f prop less than 100%, create a HIVE View with a random sample,
          # else read the entire Table
          if (prop < 1) {ore.sync(query=c('temporary_sampling'= paste0("select * from ",dat@sqlTable," where rand() <= ",prop," distribute by rand() sort by rand() limit ", n )))
          } else { ore.sync(query=c('temporary_sampling'= paste0("select * from ",dat@sqlTable))) }
          options("ore.warn.order" = FALSE)
          final <- ore.pull(temporary_sampling)
          options("ore.warn.order" = TRUE)
          cols <- paste0(paste(unlist(colnames(final)),collapse="\t"),"\n")
          rows <- apply(final,1,FUN=eachRowPrint)
          return(paste0("%table ",cols,paste0(rows, sep="",collapse = "")))
        } else
          # Check if the input is IMPALA
          if ( ore.is.connected(type='IMPALA') && (is.ore.frame(dat)) ) {
            # Future test with random sampling ore.sync(query=c('temporary_sampling'= paste0("select * from ",dat@sqlTable," tablesample system(",prop*100,") repeatable (12345)")))
            n <- min(n,nrow(dat))
            options("ore.warn.order" = FALSE)
            final <- ore.pull(head(dat,n))
            options("ore.warn.order" = TRUE)
            cols <- paste0(paste(unlist(colnames(final)),collapse="\t"),"\n")
            rows <- apply(final,1,FUN=eachRowPrint)
            return(paste0("%table ",cols,paste0(rows, sep="",collapse = "")))
          } else
            # For R Dataframe
            if (is.data.frame(dat)){
              cols <- paste0(paste(unlist(colnames(dat)),collapse="\t"),"\n")
              set.seed(1)
              if (n < nrow(dat)) {
                samp <- base::sample(nrow(dat),n)
                rows <- apply(dat[samp,],1,FUN=eachRowPrint)
              } else {rows <- apply(dat,1,FUN=eachRowPrint)}
              return(paste0("%table ",cols,paste0(rows, sep="",collapse = "")))
            } else return(paste0("INPUT Not a valid R Dataframe, HIVE or IMPALA table, nor Spark DF"))
    
  } else
    # The OML4Spark libraries are not loaded so only R Dataframes can be used
    # For R Dataframe
    if (is.data.frame(dat)){
      cols <- paste0(paste(unlist(colnames(dat)),collapse="\t"),"\n")
      set.seed(1)
      if (n < nrow(dat)) {
        samp <- base::sample(nrow(dat),n)
        rows <- apply(dat[samp,],1,FUN=eachRowPrint)
      } else {rows <- apply(dat,1,FUN=eachRowPrint)}
      return(paste0("%table ",cols,paste0(rows, sep="",collapse = "")))
    } else return(paste0("INPUT Not a valid R Dataframe, and library(ORCH) not loaded for use with other inputs"))
}
