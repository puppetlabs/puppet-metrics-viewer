#!/bin/bash

configure() {
  until curl -s http://127.0.0.1:3000 >/dev/null; do sleep 1; done

  for dashboard in /grafana-puppet/dashboard-*.json; do
    post_dashboard $dashboard
  done

  for datasource in /grafana-puppet/datasource-*.json; do
    post_datasource $datasource
  done
}

post_dashboard() {
  dashboard_json=$(cat "$1")
  post_json="{\"overwrite\": true, \"dashboard\": $dashboard_json }"
  curl -X POST \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "$post_json" \
    http://admin:admin@127.0.0.1:3000/api/dashboards/db
}

post_datasource() {
  datasource_json=$(cat "$1")
  curl -X POST \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "$datasource_json" \
    http://admin:admin@127.0.0.1:3000/api/datasources
}

configure &
exec /run.sh
