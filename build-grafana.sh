#!/bin/bash

# Save the absolute path version of the given argument for later use
#[ "${1:0:1}" = "/" ] && datadir="$1" || datadir=$(pwd)/"$1"

cd "$(dirname "$0")/grafana-puppetserver"

usage()
{
  echo
  echo "USAGE: build-grafana.sh"
  echo
}

finish() {
  docker-compose down --volumes
}

# VALIDATION

#[ ! -d "$datadir" ] && { echo "ERROR: First argument must be a directory."; usage; exit 1; }
which docker-compose || { echo "ERROR: docker-compose required. Please install docker-compose."; exit 1; }

# MAIN SCRIPT

trap finish EXIT INT

echo "Getting the latest images"
docker-compose pull --ignore-pull-failures >/dev/null 2>&1
docker-compose up -d --build

echo -n "Waiting for graphite to be ready..."
until nc -zv localhost 2003 >/dev/null 2>&1; do
  sleep 1
done
echo "ready"

echo
echo "Grafana ready! View at http://localhost:3000"
echo "Username: admin"
echo "Password: admin"
echo
echo "Press enter key to exit..."
echo

read keypress
