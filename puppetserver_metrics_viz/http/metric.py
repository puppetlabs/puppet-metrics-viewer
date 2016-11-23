class HttpMetric:
    def __init__(self, json_metric):
        self.aggregate = json_metric['aggregate']
        self.count = json_metric['count']
        self.mean = json_metric['mean']
        self.route_id = json_metric['route-id']

