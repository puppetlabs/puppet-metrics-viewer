#!/bin/bash

# VARIABLES
BUILDLOCAL=false
DATABASE="influxdb"
CONTAINERPATH="influxdb-grafana"
NETCATARGS='--netcat 127.0.0.1 --convert-to influxdb --influx-db archive'
RETENTION_DAYS=30

# ARGUMENT PARSING

usage()
{
  echo
  echo "USAGE: view-in-grafana.sh <options> [directory] <retention_days>"
  echo "Options: -d [influxdb|graphite] Enable InfluxDB or Graphite as the back end database. Defaults to InfluxDB"
  echo "         -b Build local containers from docker-compose"
}

while getopts ":bd:" opt; do
  case $opt in
    b)
      BUILDLOCAL=true
      ;;
    d)
      if [ "$OPTARG" == "graphite" ]; then
        echo "Using Graphite"
        DATABASE="graphite"
        CONTAINERPATH="grafana-puppetserver"
        NETCATARGS='--netcat 127.0.0.1'
      elif [ "$OPTARG" == "influxdb" ]; then
        echo "Using InfluxDB"
      else
        echo "Invalid database: $OPTARG" >&2
        usage
        exit 1
      fi
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

download_file() {
  curl -O --silent -k $1 || { echo "ERROR: Unable to download file from ${1}."; exit 1; }
}

download_dashboards() {
  mkdir -p ./grafana/imports
  cd ./grafana/imports
  download_file https://raw.githubusercontent.com/puppetlabs/puppet_metrics_dashboard/master/files/PuppetDB_Performance.json
  download_file https://raw.githubusercontent.com/puppetlabs/puppet_metrics_dashboard/master/files/PuppetDB_Workload.json
  download_file https://raw.githubusercontent.com/puppetlabs/puppet_metrics_dashboard/master/files/Puppetserver_Performance.json
  download_file https://raw.githubusercontent.com/puppetlabs/puppet_metrics_dashboard/master/files/Archive_File_Sync.json
  cd - > /dev/null
}

get_latest_containers() {

  if [ $BUILDLOCAL ]; then
    echo "Building local containers"
    docker-compose build >/dev/null 2>&1
  else
    echo "Downloading latest containers"
    docker-compose pull --ignore-pull-failures >/dev/null 2>&1
  fi
  if [ "$DATABASE" == "influxdb" ]; then
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
timeout=60
until nc -zv 127.0.0.1 2003 >/dev/null 2>&1 || (( timeout <= 0 )); do
  (( timeout-- ))
  sleep 1
done
(( timeout <= 0 )) && { echo "ERROR: Unable to connect to the database. Is docker running?"; exit 1; }
echo "ready"

echo "Deleting json files past ${RETENTION_DAYS} retention_days..."
NUM_DEL=$(find "$datadir" -type f -mtime +$RETENTION_DAYS -iname "*.json" -delete -print | wc -l)
echo "Deleted $NUM_DEL files past retention_days"

echo "Loading data..."
../json2graphite.rb --pattern "$datadir/"'**/*.json' $NETCATARGS 2> /dev/null

echo
echo "Metrics ready! View at http://127.0.0.1:3000"
echo "Username: admin"
echo "Password: admin"
echo
echo "Press enter key to exit..."
echo

read keypress
