#!/bin/bash

usage() {
  cat <<EOF
USAGE: view-in-grafana.sh <options> [directory] <retention_days>
Options: -d [influxdb|graphite] Enable InfluxDB or Graphite as the back end database. Defaults to InfluxDB
         -b Build local containers from docker-compose
EOF
}

finish() {
  docker-compose down --volumes
}

download_file() {
  curl -O --silent -k "$1" || { echo "ERROR: Unable to download file from ${1}."; exit 1; }
}

download_dashboards() {
  mkdir -p ./grafana/imports
  cd ./grafana/imports || exit
  download_file https://raw.githubusercontent.com/puppetlabs/puppet_metrics_dashboard/master/files/PuppetDB_Performance.json
  download_file https://raw.githubusercontent.com/puppetlabs/puppet_metrics_dashboard/master/files/PuppetDB_Workload.json
  download_file https://raw.githubusercontent.com/puppetlabs/puppet_metrics_dashboard/master/files/Puppetserver_Performance.json
  download_file https://raw.githubusercontent.com/puppetlabs/puppet_metrics_dashboard/master/files/Archive_File_Sync.json
  cd - || exit > /dev/null
}

get_latest_containers() {
  if [[ $BUILDLOCAL ]]; then
    echo "Building local containers"
    docker-compose build &>/dev/null
  else
    echo "Downloading latest containers"
    docker-compose pull --ignore-pull-failures &>/dev/null
  fi
  if [[ $DATABASE == "influxdb" ]]; then
    echo "Getting the latest graphs"
    download_dashboards
  fi

}

BUILDLOCAL=false
DATABASE="influxdb"
CONTAINERPATH="influxdb-grafana"
NETCATARGS=(--netcat 127.0.0.1 --convert-to influxdb --influx-db archive)
# Default to 30 if $2 is empty/unset
RETENTION_DAYS="${2:-30}"

while getopts ":bd:" opt; do
  case "$opt" in
    b)
      BUILDLOCAL=true
      ;;
    d)
      if [[ $OPTARG == "graphite" ]]; then
        echo "Using Graphite"
        DATABASE="graphite"
        CONTAINERPATH="grafana-puppetserver"
        NETCATARGS=(--netcat 127.0.0.1)
      elif [[ $OPTARG == "influxdb" ]]; then
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

# VALIDATION
[[ ! -d $1 ]] && { echo "ERROR: First argument must be a directory."; usage; exit 1; }

type docker-compose >/dev/null 2>&1 || {
  echo >&2 "ERROR: docker-compose required. Please install docker-compose."
  exit 1
}

# Portable way of getting the full path to a directory
datadir="$(cd "$1" || exit; echo "$PWD")"

# Download json2timeseriesdb to the directory containing this script.
cd "${BASH_SOURCE[0]%/*}" || exit
download_file https://raw.githubusercontent.com/puppetlabs/puppetlabs-puppet_metrics_collector/master/files/json2timeseriesdb
chmod +x json2timeseriesdb

# Change to the directory containing this script.
cd "${BASH_SOURCE[0]%/*}/${CONTAINERPATH}" || exit

# MAIN SCRIPT
trap finish EXIT INT ERR

echo "Getting the latest container images"
get_latest_containers
echo "Starting Containers"
docker-compose up -d

echo "Extracting data from tarballs..."
find "$datadir" -type f -ctime -"${RETENTION_DAYS}" -name "*.bz2" -execdir tar jxf "{}" \; 2>/dev/null
find "$datadir" -type f -ctime -"${RETENTION_DAYS}" -name "*.gz" -execdir tar xf "{}" \; 2>/dev/null

echo "Waiting for database to be ready..."
type nc >/dev/null 2>&1 || {
  echo >&2 "ERROR: nc required. Please install ncat/netcat."
  exit 1
}
timeout=60
until nc -zv 127.0.0.1 2003 &>/dev/null || (( timeout <= 0 )); do
  (( timeout-- ))
  sleep 1
done
(( timeout <= 0 )) && {
  echo "ERROR: Unable to connect to the database. Is docker running?"
  exit 1
}
echo "ready"

echo "Deleting json files past ${RETENTION_DAYS} retention_days..."
NUM_DEL=$(find "$datadir" -type f -mtime +"${RETENTION_DAYS}" -iname "*.json" -delete -print | wc -l)
echo "Deleted $NUM_DEL files past retention_days"

echo "Loading data..."
../json2timeseriesdb --pattern "$datadir/**/*.json" "${NETCATARGS[@]}" 2>/dev/null

cat <<EOF
Metrics ready! View at http://127.0.0.1:3000
Username: admin
Password: admin

Press enter key to exit...
EOF

# Use _ as a throwaway variable
read -r _
