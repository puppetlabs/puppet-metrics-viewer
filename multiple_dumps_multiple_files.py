import json
import argparse
import os

import puppetserver_metrics_viz.http as http

parser = argparse.ArgumentParser(description='Produce visualizations for a series of JSON metrics dumps.')
requiredNamed = parser.add_argument_group('required named arguments')
requiredNamed.add_argument('--file-prefix',
                           help='File path prefix for files containing metrics data.  All files existing at the specified path that begin with this prefix will be loaded, in order by filename.',
                           required=True)
args = parser.parse_args()

prefix = args.file_prefix

dir = os.path.dirname(prefix)
file_prefix = os.path.basename(prefix)

files = filter(lambda f: f.startswith(file_prefix), os.listdir(dir))
files.sort()
files = map(lambda f: os.path.join(dir, f), files)

def read_data(f):
    with open(f) as data_file:
        return json.load(data_file)

data = map(read_data, files)

http_metrics_series = http.HttpMetricsSeries(data)
http.multi_datapoint_line_graph(http_metrics_series)
