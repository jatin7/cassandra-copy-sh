# Repository name: cassandra-copy

## Repo Description
Linux bash scripts for Cassandra data migration.

## Scripts
1. __CassandraCopy.sh__: This is a safe script. It involves no alteration upon any keysapce or any columnfamily. This script is useful for making backup.
2. __CassandraCopyPaste.sh__: Use this script with caution. It truncates tables at your destination keyspace before it patches up tables. It makes no alteration on your source keyspace.

## _You are more welcome to change any of scripts to cater your needs._
