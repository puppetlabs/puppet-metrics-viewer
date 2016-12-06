from puppetserver_metrics_viz.jruby.metric import JRubyMetric

# TODO: combine this class with JRubyMetric, this isn't useful

class JRubyMetricMap:
    def __init__(self, timestamp, json_data):
        self.timestamp = timestamp
        self.jruby_metrics = JRubyMetric(json_data)
        # # TODO: this map probably isn't actually useful for anything,
        # # originally copied from the HTTP metrics.
        # # this whole class should potentially just be a list/collection
        # # data structure rather than a map.
        # self.metric_map = {}
        # for metric in self.jvm_metrics:
        #     self.metric_map[timestamp] = metric
