from puppetserver_metrics_viz.common.utils import Utils
from puppetserver_metrics_viz.mem.metric import MemoryMetric

class MemoryMetricsSeries:
    @staticmethod
    def __create_metric_map(json_data):
        timestamp = Utils.get_timestamp(json_data)
        return MemoryMetric(timestamp, json_data['status-service']['status']['experimental']['jvm-metrics'])

    @staticmethod
    def __get_data_point_fn_for(heap_or_nonheap, metric):
        def __get_data_point_for(x):
            # TODO: strings are cruddy here
            if heap_or_nonheap == 'heap':
                return x.heap[metric]
            else:
                return x.non_heap[metric]
        return __get_data_point_for

    def __init__(self, json_data_series):
        self.series = map(self.__class__.__create_metric_map, json_data_series)

    def __len__(self):
        return len(self.series)

    def get_data_points(self, heap_or_nonheap, metric):
        return map(self.__class__.__get_data_point_fn_for(heap_or_nonheap, metric),
                   self.series)

    # TODO: DRY up, duplicated from HTTP
    def get_timestamps(self):
        return map(lambda x: x.timestamp, self.series)