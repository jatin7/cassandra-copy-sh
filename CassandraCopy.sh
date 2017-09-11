#!/bin/bash

# Reserve temporary files
f_keyspace="__tmpFile_01.txt";
f_tables="__tmpFile_02.txt";

# Ask for Cassandra's host, keyspace, username, and password
read -p "Cassandra host: " _HOST;
read -p "Keyspace: " _KSPC;
read -p "Username: " _USER;
read -s -p "Password: " _PASS;
echo "";

# Make sure the temporary file is clean
`cat /dev/null > $f_keyspace`;

# Get the keyspace description
`cqlsh $_HOST -u $_USER -p $_PASS -e "DESCRIBE KEYSPACE "$_KSPC" ;" > $f_keyspace`;

# Extract tables from the keyspace
`sed -n 's/.*\(CREATE\ TABLE\ '$_KSPC'.\)//p' $f_keyspace | sed -n 's/\(\ (\)//p' | tee $f_tables > /dev/null`;

# Loop through tables
n=0;
while IFS='' read -r line || [[ -n "$line" ]]; do
    # Live update message
    echo "Copying table: $line";

    # Perform copy operation
    `cqlsh $_HOST -u $_USER -p $_PASS -e "COPY $_KSPC.$line TO '$line.csv' ;" > /dev/null`;

    ((n++));
done < "$f_tables";

# Last message
echo "$n table(s) copied.";

# Remove temporary files
`rm $f_keyspace`;
`rm $f_tables`;


#--------------------------------------------------
#| Author: Kamyar Nemati <kamyarnemati@gmail.com> |
#--------------------------------------------------
