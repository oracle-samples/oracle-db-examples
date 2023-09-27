load data
infile *
into table mydocs
replace
fields terminated by ','
(
  filename char(80),
  filedata LOBFILE (filename) terminated by eof
)
BEGINDATA
K:\auser\data\WordFiles\Word2007Documents\00d3b040.docx
K:\auser\data\PDF\2013920_Motorsport_Awards_Booking_Form_2013.pdf
K:\auser\data\PDF\Final Draft CGRC Dinner Invite-1.pdf
