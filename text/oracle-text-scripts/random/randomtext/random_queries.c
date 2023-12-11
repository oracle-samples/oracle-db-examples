#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/********* USER CONFIGURABLE ************/
char tab_name[]       = "mydocs";

int max_words_per_doc = 500;
int max_word_length   = 8;

char consonents[]     = "BCDFG";
char vowels[]         = "AEIO";
int  commit_after     = 10000;
/********* END USER CONFIGURABLE ********/

char mode;  /* H for HANA, O for Oracle - set in program argument */


char* getDate () {

  char * buffer = malloc(256);

  int year, month, day;
    
  char date[10];
    
  if (mode == 'H') {

    /* HANA mode */

    year  = 1960 + rand() % 50;
    month = 1 + rand() % 12;


    /* all the rest have 31 */
    day   = 1 + rand() % 31;

    /* 30 days hath September, April, June and November ... */
    if (month == 9 || month == 4 || month == 6 || month == 11) {
        day = 1 + rand() % 30;
    }
    /* except February alone */
    if (month == 2 ) {
        day = 1 + rand() % 28;
    }
    /* No I'm not going to calculate leap years */

    sprintf(buffer, "'%4d-%02d-%02d'", year, month, day);
  }
  else {

    /* Oracle mode */ 

    char smonth[4];
    char months[12][3] = { "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC" };
    char date[10];

    year   = 1960 + rand() % 50;
    month  = 1 + rand() % 12;

    strncpy (smonth, months[month-1], 3);
    smonth[3] = '\0';

    day    = 1 + rand() % 31;

    if (month == 9 || month == 4 || month == 6 || month == 11) {
        day = 1 + rand() % 30;
    }
    if (month == 2 ) {
        day = 1 + rand() % 28;
    }
    sprintf(buffer, "'%02d-%s-%04d'", day, smonth, year);
  }

  return buffer;
}


int randInt( int min, int max ) {
  return ( ( rand() % max ) + min );
}

char * getWords( int wordCount, char *conjunction ) {
  
  char tempBuff[256];
  char * retBuff;
  int num_vowels        = strlen(vowels);
  int num_consonents    = strlen(consonents);
  char word[max_word_length+1];
  
  int words_in_this_doc = (rand() % max_words_per_doc) + 1;
  int wordnum;
  
  tempBuff[0] = '\0';
  for( wordnum = 1; wordnum <= wordCount; wordnum++ ) {
    /* Minimum letters per word = 2 */
    int chars_in_this_word = (randInt( 2,  max_word_length));
    
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
    strcat( tempBuff, word);
    if ( wordnum < wordCount ) {
      strcat( tempBuff, conjunction );
    }
  }
  retBuff = malloc(strlen(tempBuff)+1);
  strcpy(retBuff, tempBuff);
  return retBuff;
} 

char * getSingleTerm( ) {
  return getWords(1, "");
}

char * getPhrase( int maxWords ) {

  /* No point in single word phrase */
  return getWords( randInt(2,maxWords), " " );
}

char * getAnd( int maxWords ) {

  /* No point in single word phrase */
  return getWords( randInt(2,maxWords), " and " );
}
  
char * getOr( int maxWords ) {

  /* No point in single word phrase */
  return getWords( randInt(2,maxWords), " or " );
}
  
char * getFuzzy() {
  
  if (mode == 'O') {
    char * str = malloc(256);
    strcpy ( str, "fuzzy(" );
    strcat ( str, getSingleTerm());
    strcat ( str, ", 70, 100)" );
    return str;
  }
  else {
    char * str = malloc(256);
    strcpy ( str, getSingleTerm());
    return str;
   }
}

/* 
  Phrase search
  AND search
  OR search
  FUZZY search
  MIXED QUERY
*/

char mode;

int xmain( int argc, char ** argv ) {
  mode = 'O';
  printf("<w>%s</w>\n", getFuzzy());
}

int main( int argc, char ** argv ) {

  int numberOfQueries = 0;

  if( argc != 3 ) {
    fprintf( stderr, "usage: %s <number_docs> O|H\n", argv[0] );
    exit( -1 );
  }
  else {
    numberOfQueries = atoi(argv[1]);
    if( numberOfQueries < 1 ) {
      fprintf( stderr, "usage: %s <number_docs> [<number_partitions>]\n", argv[0] );
      fprintf( stderr, "number_docs must be a positive integer\n");
      exit( -1 );
    }
    if (argv[2][0] == 'O') {
        mode = 'O';
    }
    else {
        if (argv[2][0] == 'H') {
            mode = 'H';
        }
        else {
            fprintf( stderr, "mode must be O for Oracle or H for HANA\n" );
            exit( -1 );
        }
    }
  
  }

  int i;
/* 
  Phrase search
  AND search
  OR search
  FUZZY search
  MIXED QUERY
*/

  char intro[256];
  char outro[256];
  char out1[256];
  char out2[256];
  char countIntro[256];
  char countOutro[256];
  char fuzzyExtra[256];
  
  static char oraIntro[] = "select * from ( select score(1), artid, author from texttable where contains( text, '";
  static char oraOutro[] = "', 1 ) > 0 order by score(1) desc ) where rownum <= 10;";
  static char ora1[]     = "', 1) > 0 ";
  static char ora2[]     = " order by score(1) desc) where rownum <= 10;";
  
  static char hanaIntro[] = "select top 10 score() as score, artid, author from texttable where contains( text, '";
  static char hanaOutro[] = "') order by score desc;";
  static char han1[]      = "') ";
  static char han2[]      = " order by score desc;";

  static char oraCountIntro[] = "select ctx_query.count_hits('TEXTINDEX', '";
  static char oraCountOutro[] = "') as Count from dual;";

  static char hanaCountIntro[] = "select count(*) from texttable where contains( text, '";
  static char hanaCountOutro[] = "');";

  static char oraFuzzyExtra[] = "";
  static char hanaFuzzyExtra[] = "', 'FUZZY(0.9, textSearch=compare, bestMatchingTokenWeight=0.9)";

  /* stuff to write at start of query file */

  static char oraPreBlurb[] = "column author format a30\nset timing on\nset echo on\n";
  static char hanaPreBlurb[] = "";

  if (mode == 'O') {
     strcpy(intro, oraIntro);
     strcpy(outro, oraOutro);
     strcpy(countIntro, oraCountIntro);
     strcpy(countOutro, oraCountOutro);
     strcpy(fuzzyExtra, oraFuzzyExtra);
     strcpy(out1, ora1);
     strcpy(out2, ora2);
     printf(oraPreBlurb);
  }
  else {
     strcpy(intro, hanaIntro);
     strcpy(outro, hanaOutro);
     strcpy(countIntro, hanaCountIntro);
     strcpy(countOutro, hanaCountOutro);
     strcpy(fuzzyExtra, hanaFuzzyExtra);
     strcpy(out1, han1);
     strcpy(out2, han2);
     printf(hanaPreBlurb);
  }       

  /* Single Term */
  for( i = 0; i < numberOfQueries; i++) {
    char * x = getSingleTerm();
    printf("%s%s%s\n", intro, x, outro);
    printf("%s%s%s\n", countIntro, x, countOutro);
  }
  /* AND */
  for( i = 0; i < numberOfQueries; i++) {
    char * x = getAnd(4);
    printf("%s%s%s\n", intro, x, outro);
    printf("%s%s%s\n", countIntro, x, countOutro);
  }
  /* OR */
  for( i = 0; i < numberOfQueries; i++) {
    char * x = getOr(4);
    printf("%s%s%s\n", intro, x, outro);
    printf("%s%s%s\n", countIntro, x, countOutro);
  }
  /* FUZZY */
  for( i = 0; i < numberOfQueries; i++) {
    char * x = getFuzzy();
    printf("%s%s%s%s\n", intro, x, fuzzyExtra, outro);
    printf("%s%s%s%s\n", countIntro, x, fuzzyExtra, countOutro);
  }

  /* Mixed queries */
  /* Use an OR query combined with a date restriction */

  for( i = 0; i < numberOfQueries; i++) {
    char *date1 = getDate();
    char *date2 = getDate();
    char * x = getOr(4);
    printf("%s%s%s", intro, x, out1);
    printf("and artdate between %s and %s%s\n", date1, date2, out2);
    if (mode == 'H') {
      printf("%s%s%s", countIntro, x, out1);
      printf("and artdate between %s and %s%s\n", date1, date2, ";");
    }
  }

}
