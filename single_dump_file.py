#!/usr/bin/env python
import json
import argparse

import puppetserver_metrics_viz.http as http

parser = argparse.ArgumentParser(description='Produce visualizations for a single JSON metrics dump from a specified file.')
parser.add_argument('--infile', help='File to parse JSON metrics from', )
args = parser.parse_args()

infile = args.infile

with open(infile) as data_file:
    data = json.load(data_file)

http_metrics = http.HttpMetricMap(data['pe-master']['status']['experimental']['http-metrics'])
http.single_datapoint_bar_graph(http_metrics)
