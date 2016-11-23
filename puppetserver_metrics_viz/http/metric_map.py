from puppetserver_metrics_viz.http.metric import HttpMetric

class HttpMetricMap:
    def __init__(self, json_data):
        http_metrics = map(lambda x: HttpMetric(x), json_data)
        # TODO: make 'total' filtering and cutoff threshold configurable
        http_metrics = filter(lambda x: x.route_id != 'total', http_metrics)
        max_aggregate = max(map(lambda x: x.aggregate, http_metrics))
        cutoff = max_aggregate / 10000.0
        self.http_metrics = filter(lambda x: x.aggregate > cutoff, http_metrics)

    def __iter__(self):
        return iter(self.http_metrics)

