# Generate random text for inserting into a table
# creates a SQL script for loading with SQL*Plus
#
#  Words are constructed of consonents and vowels alternating
#  only a few characters are used to make sure there are not too many permutations
#  (20 possible 2 letter words, 100 x 3 letter, 400 x 4 letter, 2000 x 5 letter, etc)
#  Add more or less letters to alter the permutations
#
#  Script is not that fast - takes half an hour or so to create 
#  1 million documents (about 1GB of text at max 500 words per doc)
#  - about 30,000 documents per minute
# 
#  This version creates the table as well
#  Note: 500 words of 8 chars may occasionally blow the SQL*Plus string size limit
#  We don't bother to trap that, may mean you get one or two rows per million
#  which fail to load.

use strict;

##################################################
# PARAMETERS YOU CAN CHANGE:

my $num_docs          = 1000000;
my $num_partitions    = 1;
my $tab_name          = "docs";

my $max_words_per_doc = 200;
my $max_word_length   = 8;

my @consonents        = ( "B","C","D","F","G" );
my @vowels            = ( "A", "E", "I", "O" );

# END OF PARAMETERS
##################################################

# Create the DDL ( drop / create table statements )

print "drop table " . $tab_name . ";\n\n";

print "create table " . $tab_name . " (id number primary key, text varchar2(4000))\n";

if ($num_partitions > 1) {
    print "partition by range (id) (\n";

    my $range_step = $num_docs / $num_partitions;
    my $range_limit = $range_step;
    my $p_num = 1;
    my $comma = " ";
    
    do {
        print "   " . $comma . " partition p" . $p_num++ . " values less than (" . int($range_limit + 1) . ")\n";
        $comma = ",";
        $range_limit += $range_step;
    } until  ($range_limit > $num_docs);
    
    print ")";
}
print ";\n\n";

# Create the DML ( insert into ... statements )

# for each doc
foreach my $docnum ((1000000...$num_docs+1000000)) {
    print "insert into " . $tab_name . " values ( $docnum, '";
    my $words_in_this_doc = rand($max_words_per_doc);
    # for each word
    foreach my $wordnum ((1...$words_in_this_doc)) {
        my $chars_in_this_word = rand($max_word_length);
        my $word = "";            
        # for each char
        foreach my $k ((1...$chars_in_this_word)) {
            my $remainder = $k % 2;
            if ( $remainder ) {
                my @c = @consonents;
                my $char = splice(@c, int(rand(@consonents)), 1);
                $word .= $char;
            }
            else {
                my @c = @vowels;
                my $char = splice(@c, int(rand(@vowels)), 1);
                $word .= $char;
            }
        }
        print $word . " ";
    }
    print "');\n";

    # Commit every 10000 rows
    my $commitpoint = $docnum % 10000;
    if ($commitpoint == 0) {
        print "commit;\n";
    }
}
print "commit;\n";
