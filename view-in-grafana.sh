#!/bin/bash

# Save the absolute path version of the given argument for later use
[ "${1:0:1}" = "/" ] && datadir="$1" || datadir=$(pwd)/"$1"

if [ "$2" != "" ]; then
  RETENTION_DAYS=$2
else
  RETENTION_DAYS=30
fi


cd "$(dirname "$0")/grafana-puppetserver"

usage()
{
  echo
  echo "USAGE: view-in-grafana.sh <directory> <retention_days>"
  echo
}

finish() {
  docker-compose down --volumes
}

# VALIDATION

[ ! -d "$datadir" ] && { echo "ERROR: First argument must be a directory."; usage; exit 1; }
which docker-compose || { echo "ERROR: docker-compose required. Please install docker-compose."; exit 1; }

# MAIN SCRIPT

trap finish EXIT INT

echo "Getting the latest images"
echo "docker-pull"
docker-compose pull --ignore-pull-failures >/dev/null 2>&1
echo "docker-up"
docker-compose up -d

echo "Waiting for graphite to be ready..."
until nc -zv localhost 2003 >/dev/null 2>&1; do
  sleep 1
done
echo "ready"

echo "Extracting data from tarballs..."
find $datadir -type f -ctime -$RETENTION_DAYS -iname "*.bz2" -exec bash -c 'tar jxf "{}" -C $(dirname "{}")' \; 2>/dev/null;

echo "Deleting json files past retention_days..."
NUM_DEL=$(find $datadir -type f -mtime +$RETENTION_DAYS -iname "*.json" -delete -print | wc -l)
echo "Deleted $NUM_DEL files past retention_days"

echo "Loading data..."
../json2graphite.rb --pattern "$datadir/"'**/*.json' --netcat localhost

echo
echo "Metrics ready! View at http://localhost:3000"
echo "Username: admin"
echo "Password: admin"
echo
echo "Press enter key to exit..."
echo

read keypress
