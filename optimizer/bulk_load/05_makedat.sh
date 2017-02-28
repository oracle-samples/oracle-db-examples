#
# This directory should be the same as
# the one referenced in the 01_dirs.sql
# script.
#
# It creates four example data files and
# the "unc.sh" script.
# If you want to do some more serious volume tests,
# you can make the ROWCOUNT larger but it could
# take some time to complete!
#
DIR=/home/oracle/direct
ROWCOUNT=1000

if [ ! -d ${DIR} ]
then
  echo "ERROR:"
  echo "Before running this script you will need to create"
  echo "an empty directory called ${DIR}. "
  echo "If you want to use a different directory, then edit"
  echo "this script to change its location and also change"
  echo "the name of the directory in 01_dirs.sql and re-run"
  echo "that SQL script too."
  exit 2
fi

FILE1=${DIR}/sales_1.dat
FILE2=${DIR}/sales_2.dat
FILE1Z=${DIR}/sales_1.dat.gz
FILE2Z=${DIR}/sales_2.dat.gz

rm -r ${FILE1} 2>/dev/null
rm -r ${FILE2} 2>/dev/null
rm -r ${FILE1Z} 2>/dev/null
rm -r ${FILE2Z} 2>/dev/null

echo "Creating DAT file 1..."

for i in {1..${ROWCOUNT}}
do
   echo "${i}|XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> ${FILE1}
done

echo "Creating DAT file 2..."

cp ${FILE1} ${FILE2}

echo "Creating GZIP files..."

cd ${DIR}
gzip<${FILE1}>${FILE1Z}
gzip<${FILE2}>${FILE2Z}

echo "Creating unc.sh script..."
echo "/bin/gunzip -c \$1" > ${DIR}/unc.sh
chmod +x ${DIR}/unc.sh
