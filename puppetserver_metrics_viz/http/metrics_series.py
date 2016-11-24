from puppetserver_metrics_viz.http import HttpMetricMap


class HttpMetricsSeries:
    def __init__(self, json_data_series):
        self.series = map(lambda x: HttpMetricMap(x['pe-master']['status']['experimental']['http-metrics']),
                          json_data_series)

    def __iter__(self):
        return iter(self.series)

    def __len__(self):
        return len(self.series)

    @staticmethod
    def __get_data_point_fn_for(route_id, metric):
        def __get_data_point_for(x):
            if not (route_id in x.keys()):
                return 0
            else:
                return getattr(x[route_id], metric)
        return __get_data_point_for


    def get_data_points(self, route_id, metric):
        return map(HttpMetricsSeries.__get_data_point_fn_for(route_id, metric),
                   self.series)



