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
read -p "Host: " HOST_d;
read -p "Keyspace: " KSPC_d;
read -p "Username: " USER_d;
read -s -p "Password: " PASS_d;
echo "";

# Ask for user confirmation to proceed
ans_n="no";
ans_y="yes";
l=`wc -l < $f_tables`;
echo "WARNING! You are about to enter the danger zone.";
echo "The following actions need your confirmation.";
echo "1. Copy $l table(s) from $_KSPC@$_HOST";
echo "2. Truncate respective tables at $KSPC_d@$HOST_d";
echo "3. Patch up tables to $KSPC_d@$HOST_d";
while [[ $p != @($ans_n|$ans_y) ]]; do
    read -p "Are you sure you want to proceed? (yes)/(no): " p;
done

# Loop through tables if user has confirmed
if [[ $p == $ans_y ]]; then
    n=0;
    while IFS='' read -r line || [[ -n "$line" ]]; do
        # Perform copy operation
        echo "Copying table: $line";
        `cqlsh $_HOST -u $_USER -p $_PASS -e "COPY $_KSPC.$line TO '$line.$ext' ;" > /dev/null`;

        # Clean up the table at the destination keyspace
        echo "Truncating table: $line";
        `cqlsh $HOST_d -u $USER_d -p $PASS_d -e "TRUNCATE TABLE $KSPC_d.$line ;" > /dev/null`;

        # Patch up the table at the destination keyspace
        echo "Pasting table: $line";
        `cqlsh $HOST_d -u $USER_d -p $PASS_d -e "COPY $KSPC_d.$line FROM '$line.$ext' ;" > /dev/null`;

        # Remove the copied table file
        `rm $line.$ext`;

        ((n++));
    done < "$f_tables";

    # Last message
    echo "$n table(s) copied.";
else
    echo "Operation canceled by user.";
fi

# Remove temporary files
`rm $f_keyspace`;
`rm $f_tables`;


#--------------------------------------------------
#| Author: Kamyar Nemati <kamyarnemati@gmail.com> |
#--------------------------------------------------
