# grafana-puppetserver

## Introduction

This directory contains Docker tools to build and run a Graphite/Statsd/Grafana
stack configured to consume and display Puppet metrics.

## Important Components

### Dockerfile

The included Dockerfile builds the grafana-puppetserver image. This image runs
Grafana, and will be configured with dashboards for viewing Puppet metrics.

### docker-compose.yml

The docker-compose.yml file defines the full stack necessary to view metrics,
which includes the grafana-puppetserver image and the graphite-statsd image.

### build/

The build/ directory is how to update dashboards or other Grafana configuration
in the graphite-statsd image. Any dashboard json file placed in this directory,
following the naming convention "dashboard-\*.json", will be added to the
grafana-puppetserver image when built.

Similarly, the datasource(s) are defined here with the naming convention
"datasource-\*.json".

The run.sh script is the entrypoint for the grafana-puppetserver image and
loads all the defined configuration into Grafana when the image boots.

Because the official Grafana image uses a volume for /var/lib/grafana, it is
not possible to bake the dashboard configuration into the image without either
modifying the Grafana configuration to use a different directory, or taking an
approach like this one which loads the dashboards on boot.
