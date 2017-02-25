#!/bin/bash

datasource_name="graphite-statsd"
g_id=1

configure() {
  until curl -s http://127.0.0.1:3000 >/dev/null; do sleep 1; done

  for datasource in /grafana-puppet/datasource-*.json; do
    post_datasource $datasource
  done

  for dashboard in /grafana-puppet/dashboard-*.json; do
    post_dashboard $dashboard
  done
}

post_dashboard() {
  dashboard=$(cat "$1" | sed "s/\\\${DS_GRAPHITE-STATSD}/$datasource_name/")
  json="{\"overwrite\": true, \"dashboard\": $dashboard }"
  post "/api/dashboards/db" "$json"
  post "/api/user/stars/dashboard/$g_id"
  g_id=$(expr "$g_id" + 1)
}

post_datasource() {
  json=$(cat "$1")
  post "/api/datasources" "$json"
}

post() {
  curl -X POST \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "$2" \
    "http://admin:admin@127.0.0.1:3000${1}"
}

configure &
exec /run.sh
