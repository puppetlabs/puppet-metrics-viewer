from puppetserver_metrics_viz.common.utils import Utils
from puppetserver_metrics_viz.jruby.metric import JRubyMetric

class JRubyMetricsSeries:
    @staticmethod
    def __create_metric_map(json_data):
        timestamp = Utils.get_timestamp(json_data)
        return JRubyMetric(timestamp, json_data['pe-jruby-metrics']['status']['experimental']['metrics'])

    @staticmethod
    def __get_data_point_fn_for(metric):
        def __get_data_point_for(x):
            return getattr(x, metric)
        return __get_data_point_for

    def __init__(self, json_data_series):
        self.series = map(self.__class__.__create_metric_map, json_data_series)

    def __len__(self):
        return len(self.series)

    def get_data_points(self, metric):
        return map(self.__class__.__get_data_point_fn_for(metric),
                   self.series)

    # TODO: DRY up, duplicated from HTTP
    def get_timestamps(self):
        return map(lambda x: x.timestamp, self.series)