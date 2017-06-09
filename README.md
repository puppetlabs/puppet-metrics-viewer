# puppet-metrics-viewer

This repo contains a CLI tool for generating visualizations of your puppet
metrics data.  It assumes you have collected the metrics using  [npwalker/pe_metric_curl_cron_jobs](https://github.com/npwalker/pe_metric_curl_cron_jobs).

## View metrics in Grafana

![screenshot](./images/grafana.jpg)

 The `json2graphite.rb` script can be used to transform data in JSON files into a format that can be fed into Graphite.

To run this code, you will need [Docker](https://www.docker.com/products/overview) (and docker-compose) installed.  _Tip:_ If you're using a Mac, use the official Mac packages instead of installing from brew.  (If you figure out how to use this with docker installed from brew let us know)

With Docker installed, you can run the script `view-in-grafana.sh`, passing it the directory containing the data files to load into Graphite. e.g.

```
./view-in-grafana.sh ~/Downloads/pe_metrics/puppet_server
```

You can then view the metrics by visting `http://localhost:3000` in your browser.
 - username: `admin`
 - password: `admin`.

### Export data to pre-existing Graphite

The `json2graphite.rb` script can be used to transform data in the JSON files into a format that can be fed into any Graphite instance.

Usage:

```
./json2graphite.rb [--pattern PATTERN] [filename_1 ... filename_n]
```

Output will be lines in Graphite's plain text input format. This output can be fed through a tool like `nc` to inject it into Graphite.

Examples:

```
./json2graphite.rb ~/Downloads/logdump/puppetserver/*.json | nc localhost 2003
```

The simple example can be used for small numbers of files. When more files exist than can be referenced as arguments, use `--pattern`.

```
./json2graphite.rb --pattern '~/Downloads/logdump/puppetserver/*.json' | nc localhost 2003
```

The `--pattern` flag accepts a Ruby glob argument, which Ruby will then expand into a list of files to process.

## Standup Grafana without importing data

This branch contains a script `build-grafana.sh` to standup a Grafana instance
without importing any data. It uses a locally-built docker container, rather
than an image from docker hub.

To make modifications, alter the files in `grafana-puppetserver/` and then in
that directory run `docker-compose up --build --force-recreate`. `Ctrl-C` to
exit, and then run `docker-compose down --volumes` to stop completely (only
needed if you want to completely restart the containers).

On Mac, there appears to be a problem where if you put your computer to sleep
with containers running, they will wake up with time out of sync from your
laptop. This can be fixed by restarting Docker (can be done from the menu
bar).

You can check the container's time easily by running

```
docker exec -it graphite-statsd date
```
