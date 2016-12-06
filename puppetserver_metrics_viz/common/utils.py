class Utils:
    @staticmethod
    def get_timestamp(json_data):
        jvm_metrics = json_data['status-service']['status']['experimental']['jvm-metrics']
        start_time = jvm_metrics['start-time-ms'] / 1000
        up_time = jvm_metrics['up-time-ms'] / 1000
        return start_time + up_time