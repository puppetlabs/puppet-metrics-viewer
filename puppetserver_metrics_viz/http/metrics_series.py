from puppetserver_metrics_viz.http import HttpMetricMap

class HttpMetricsSeries:
    def __init__(self, json_data_series):
        self.series = map(lambda x: HttpMetricMap(x['pe-master']['status']['experimental']['http-metrics']),
                          json_data_series)

    def __iter__(self):
        return iter(self.series)

    def __len__(self):
        return len(self.series)


