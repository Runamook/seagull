#!/bin/bash

#  "string";"string";"string";"string";
#  # "framed-ip","imsi";"msisdn";"imei"
#  # "172.16.1.1";"250999000000001";"79990000001";"3548170784554801"
#  "0xaa100101";"250999000000001";"79990000001";"3548170784554801";
#  "0xaa100102";"250999000000002";"79990000002";"3548170784554802";

OFILE=${1:-test.txt}
RECORD_AMOUNT=$2
IMSI_START=${3:-250999000000000}
MSISDN_START=${4:-79990000000}
IP_START="AA100101"

TEMP_FILE=./.temp_file.txt

# Generate file head
echo -e "Cleaning $OFILE"
echo -e "Generating a file with \n\nstart IMSI: $IMSI_START \nstart MSISDN: $MSISDN_START \nIP: $IP_START \n$RECORD_AMOUNT records"

/bin/rm -f $OFILE

cat > $TEMP_FILE <<EOF
"string";"string";"string";"string";
# "framed-ip","imsi";"msisdn";"imei"
# "172.16.1.1";"250999000000001";"79990000001";"3548170784554801"
EOF

for i in $(seq $RECORD_AMOUNT); do
	let IMSI=$IMSI_START+$i
	let MSISDN=$MSISDN_START+$i
	IP_ADDR=$(echo "obase=16;ibase=16;$IP_START + $i" | bc)
	echo "\"$IP_ADDR\";\"$IMSI\";\"$MSISDN\";\"3548170784554801\"" >> $TEMP_FILE
done

tr '[:upper:]' '[:lower:]' < $TEMP_FILE > $OFILE

/bin/rm -f $TEMP_FILE
