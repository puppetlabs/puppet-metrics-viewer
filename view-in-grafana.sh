#!/bin/bash

# Save the absolute path version of the given argument for later use
[ "${1:0:1}" = "/" ] && datadir="$1" || datadir=$(pwd)/"$1"

cd "$(dirname "$0")/grafana-puppetserver"

usage()
{
  echo
  echo "USAGE: view-in-grafana.sh <directory>"
  echo
}

finish() {
  docker-compose down
}

# VALIDATION

[ ! -d "$datadir" ] && { echo "ERROR: First argument must be a directory."; usage; exit 1; }
which docker-compose || { echo "ERROR: docker-compose required. Please install docker-compose."; exit 1; }

# MAIN SCRIPT

trap finish EXIT INT 

docker-compose up -d

echo -n "Waiting for graphite to be ready..."
until nc -zv localhost 2003 >/dev/null 2>&1; do
  sleep 1
done
echo "ready"

echo -n "Loading data..."
find "$datadir" -name '*.json' | xargs ../json2graphite.rb | nc localhost 2003
echo " loaded"

echo
echo "Metrics ready! View at http://localhost:3000"
echo "Username: admin"
echo "Password: admin"
echo
echo "Press enter key to exit..."
echo

read keypress
