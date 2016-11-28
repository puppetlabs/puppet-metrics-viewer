class MemoryMetric:
    BYTES_PER_MEGABYTE = 1024 * 1024

    def __init__(self, json_metric):
        self.heap = {
            'committed': json_metric['heap-memory']['committed'] / MemoryMetric.BYTES_PER_MEGABYTE,
            'init': json_metric['heap-memory']['init'] / MemoryMetric.BYTES_PER_MEGABYTE,
            'max': json_metric['heap-memory']['max'] / MemoryMetric.BYTES_PER_MEGABYTE,
            'used': json_metric['heap-memory']['used'] / MemoryMetric.BYTES_PER_MEGABYTE
        }
        self.non_heap = {
            'committed': json_metric['non-heap-memory']['committed'] / MemoryMetric.BYTES_PER_MEGABYTE,
            'init': json_metric['non-heap-memory']['init'] / MemoryMetric.BYTES_PER_MEGABYTE,
            'max': json_metric['non-heap-memory']['max'] / MemoryMetric.BYTES_PER_MEGABYTE,
            'used': json_metric['non-heap-memory']['used'] / MemoryMetric.BYTES_PER_MEGABYTE
        }
        self.start_time_ms = json_metric['start-time-ms']
        self.up_time_ms = json_metric['up-time-ms']