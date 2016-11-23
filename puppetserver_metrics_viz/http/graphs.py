import matplotlib.pyplot as plt
import numpy as np

def single_datapoint_bar_graph(http_metrics):
    requests = map(lambda x: x.route_id, http_metrics)
    y_pos = np.arange(len(requests))
    aggregate = map(lambda x: x.aggregate, http_metrics)

    plt.barh(y_pos, aggregate, align='center', alpha=0.5)
    plt.yticks(y_pos, requests)
    plt.ylabel('HTTP Endpoints')
    plt.xlabel('Response time (ms)')
    plt.title('Aggregate Request Response Time')
    plt.tight_layout()
    plt.show()