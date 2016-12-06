class JRubyMetric:
    def __init__(self, json_metric):
        self.average_borrow_time = json_metric['average-borrow-time']
        self.average_wait_time = json_metric['average-wait-time']
        self.average_free_jrubies = json_metric['average-free-jrubies']
        self.average_requested_jrubies = json_metric['average-requested-jrubies']