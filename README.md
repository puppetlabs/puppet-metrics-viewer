# puppet-metrics-viewer

This repository contains a CLI tool for generating visualizations of your puppet
metrics data.  It assumes you have collected the metrics using  [puppetlabs/puppet_metrics_collector](https://forge.puppet.com/puppetlabs/puppet_metrics_collector).

## View metrics in Grafana

![Screen shot](./images/grafana.jpg)

 The `json2timeseriesdb` script can be used to transform data in JSON files into a format that can be fed into Graphite.

To run this code, you will need [Docker](https://www.docker.com/products/overview) (and docker-compose) installed.  _Tip:_ If you're using a Mac, use the official Mac packages instead of installing from brew.  (If you figure out how to use this with docker installed from brew let us know)

With Docker installed, you can run the script `view-in-grafana.sh`, passing it the directory containing the data files to load into Graphite. e.g.

```
./view-in-grafana.sh ~/Downloads/puppet_metrics/puppetserver
```

You can then view the metrics by visiting `http://localhost:3000` in your browser.
 - username: `admin`
 - password: `admin`.

### Advanced Options for viewing metrics with grafana
The `view-in-grafana.sh` script has several options that can change the behavior of the environment.

#### Limit the data that will be imported

By default, the script uses a retention of 30 days. You can specify a different retention period if desired.

```
./view-in-grafana.sh ~/Downloads/puppet_metrics/puppetserver 10
```

_Note:_ `.json` files outside the retention period will be deleted as the assumption is that they exist in the tar archives.

#### Use Graphite as the backend database
By default, InfluxDB is used to store the data. New capabilities have been built to use InfluxDB as the backend database in `json2timeseriesdb` and can be used as the backend database container. Graphite can be used as well with the following option. 

```
./view-in-grafana.sh -d graphite  ~/Downloads/puppet_metrics/puppetserver
```

#### Build the local containers instead of from Docker hub
To test dashboard updates, you can specify the `-b` option to build the local `grafana-puppetserver` container.

```
./view-in-grafana.sh -b ~/Downloads/puppet_metrics/puppetserver

```

## Export data to pre-existing Graphite or InfluxDB

The `json2timeseriesdb` script can be used to transform data in the JSON files into a format that can be fed into any Graphite or InfluxDB instance.

Usage:

```
./json2timeseriesdb [--pattern PATTERN] [filename_1 ... filename_n]
```

Output will be lines in Graphite's plain text input format. The output can be sent to a host running graphite by passing a hostname to the `--netcat` flag.

Examples:

```
./json2timeseriesdb ~/Downloads/logdump/puppetserver/*.json --netcat localhost
```

The `--netcat` flag will send output to port 2003. A custom port can be used by piping STDOUT to `nc` instead:

```
./json2timeseriesdb ~/Downloads/logdump/puppetserver/*.json | nc localhost 4242
```

This simple example can be used for small number of files. For a large number of files, use `--pattern`.

```
./json2timeseriesdb --pattern '~/Downloads/logdump/puppetserver/*.json' --netcat localhost
```

The `--pattern` flag accepts a Ruby glob argument, which the script will internally expand into a list of files.

InfluxDB output can be produced using the `--convert-to` flag:

```
./json2timeseriesdb ~/Downloads/logdump/puppetserver/*.json --convert-to influxdb
```

When `--netcat` is used with InfluxDB output, data will be sent to port 8086. The `--influx-db` flag must also be used to specify a database to write to:

```
./json2timeseriesdb ~/Downloads/logdump/puppetserver/*.json --convert-to influxdb --netcat localhost --influx-db pe-metrics
```
