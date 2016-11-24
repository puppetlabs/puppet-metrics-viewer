from puppetserver_metrics_viz.http import HttpMetricMap

class HttpMetricsSeries:
    @staticmethod
    def __create_metric_map(json_data):
        jvm_metrics = json_data['status-service']['status']['experimental']['jvm-metrics']
        start_time = jvm_metrics['start-time-ms'] / 1000
        up_time = jvm_metrics['up-time-ms'] / 1000
        timestamp = start_time + up_time
        return HttpMetricMap(timestamp, json_data['pe-master']['status']['experimental']['http-metrics'])

    @staticmethod
    def __get_data_point_fn_for(route_id, metric):
        def __get_data_point_for(x):
            if not (route_id in x.keys()):
                return 0
            else:
                return getattr(x[route_id], metric)
        return __get_data_point_for


    def __init__(self, json_data_series):
        self.series = map(self.__class__.__create_metric_map,
                          json_data_series)

    def __iter__(self):
        return iter(self.series)

    def __len__(self):
        return len(self.series)

    def get_data_points(self, route_id, metric):
        return map(self.__class__.__get_data_point_fn_for(route_id, metric),
                   self.series)

    def get_timestamps(self):
        return map(lambda x: x.timestamp, self.series)



