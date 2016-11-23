import json
import os

import puppetserver_metrics_viz.http as http

data_dir = "./target/pe_metrics/puppet_server"
data_file_path = os.path.join(data_dir, "oser501990.wal-mart.com-11_18_16_20:15.json");

with open(data_file_path) as data_file:
    data = json.load(data_file)

http_metrics = http.HttpMetricMap(data['pe-master']['status']['experimental']['http-metrics'])
http.single_datapoint_bar_graph(http_metrics)