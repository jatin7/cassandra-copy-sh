#!/bin/bash

# Reserve temporary files
f_keyspace="__tmpFile_01.txt";
f_tables="__tmpFile_02.txt";

# File extension for copied data from tables
ext="csv";

# Ask for Cassandra's host, keyspace, username, and password
echo "---------------Source Keyspace---------------";
read -p "Host: " _HOST;
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

# Ask for destination Cassandra's host, keyspace, username, and password
echo "-------------Destination Keyspace------------";
read -p "Host: " HOST_;
read -p "Keyspace: " KSPC_;
read -p "Username: " USER_;
read -s -p "Password: " PASS_;
echo "";

# Loop through tables
n=0;
while IFS='' read -r line || [[ -n "$line" ]]; do
    # Perform copy operation
    echo "Copying table: $line";
    `cqlsh $_HOST -u $_USER -p $_PASS -e "COPY $_KSPC.$line TO '$line.$ext' ;" > /dev/null`;

    # Clean up the table at the destination keyspace
    echo "Truncating table: $line";
    `cqlsh $HOST_ -u $USER_ -p $PASS_ -e "TRUNCATE TABLE $KSPC_.$line ;" > /dev/null`;

    # Patch up the table at the destination keyspace
    echo "Pasting table: $line";
    `cqlsh $HOST_ -u $USER_ -p $PASS_ -e "COPY $KSPC_.$line FROM '$line.$ext' ;" > /dev/null`;

    # Remove the copied table file
    `rm $line.$ext`;

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
