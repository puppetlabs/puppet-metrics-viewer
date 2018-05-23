#!/bin/bash

# VARIABLES
BUILDLOCAL=false
INFLUXDB=false
CONTAINERPATH="grafana-puppetserver"
NETCATARGS='--netcat localhost'
RETENTION_DAYS=30

# ARGUMENT PARSING

usage()
{
  echo
  echo "USAGE: view-in-grafana.sh <options> [directory] <retention_days>"
  echo "Options: -i Enable InfluxDB"
  echo "         -b Build local containers from docker-compose"
}

while getopts ":bi" opt; do
  case $opt in
    b)
      BUILDLOCAL=true
      ;;
    i)
      echo "Using InfluxDB"
      INFLUXDB=true
      CONTAINERPATH="influxdb-grafana"
      NETCATARGS='--netcat localhost --convert-to influxdb --influx-db archive'
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

# Save the absolute path version of the given argument for later use
[ "${1:0:1}" = "/" ] && datadir="$1" || datadir=$(pwd)/"$1"

if [ "$2" != "" ]; then
  RETENTION_DAYS=$2
fi

# FUNCTIONS

cd "$(dirname "$0")/${CONTAINERPATH}"

finish() {
  docker-compose down --volumes
}

download_dashboards() {
  mkdir -p ./grafana/imports
  wget -q -N -P ./grafana/imports https://raw.githubusercontent.com/puppetlabs/puppetlabs-pe_metrics_dashboard/master/files/PuppetDB_Performance.json
  wget -q -N -P ./grafana/imports https://raw.githubusercontent.com/puppetlabs/puppetlabs-pe_metrics_dashboard/master/files/PuppetDB_Workload.json
  wget -q -N -P ./grafana/imports https://raw.githubusercontent.com/puppetlabs/puppetlabs-pe_metrics_dashboard/master/files/Puppetserver_Performance.json
}

get_latest_containers() {

  if [ $BUILDLOCAL ]; then
    echo "Building local containers"
    docker-compose build >/dev/null 2>&1
  else
    echo "Downloading latest containers"
    docker-compose pull --ignore-pull-failures >/dev/null 2>&1
  fi
  if [ $INFLUXDB ]; then
    echo "Getting the latest graphs"
    download_dashboards
  fi

}

# VALIDATION

[ ! -d "$datadir" ] && { echo "ERROR: First argument must be a directory."; usage; exit 1; }
which docker-compose >/dev/null 2>&1 || { echo "ERROR: docker-compose required. Please install docker-compose."; exit 1; }

# MAIN SCRIPT

trap finish EXIT INT

echo "Getting the latest container images"
get_latest_containers
echo "Starting Containers"
docker-compose up -d

echo "Extracting data from tarballs..."
find "$datadir" -type f -ctime -$RETENTION_DAYS -iname "*.bz2" -exec bash -c 'tar jxf "{}" -C $(dirname "{}")' \; 2>/dev/null;
find "$datadir" -type f -ctime -$RETENTION_DAYS -iname "*.gz" -exec bash -c 'tar xf "{}" -C $(dirname "{}")' \; 2>/dev/null;

echo "Waiting for database to be ready..."
until nc -zv localhost 2003 >/dev/null 2>&1; do
  sleep 1
done
echo "ready"

echo "Deleting json files past ${RETENTION_DAYS} retention_days..."
NUM_DEL=$(find "$datadir" -type f -mtime +$RETENTION_DAYS -iname "*.json" -delete -print | wc -l)
echo "Deleted $NUM_DEL files past retention_days"

echo "Loading data..."
../json2graphite.rb --pattern "$datadir/"'**/*.json' $NETCATARGS >/dev/null

echo
echo "Metrics ready! View at http://localhost:3000"
echo "Username: admin"
echo "Password: admin"
echo
echo "Press enter key to exit..."
echo

read keypress
