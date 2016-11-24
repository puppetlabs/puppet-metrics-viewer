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


def multi_datapoint_line_graph(http_metrics_series):
    x_pos = np.arange(len(http_metrics_series))
    # TODO: use keys from metrics maps rather than hard-coding them here
    catalog = http_metrics_series.get_data_points('puppet-v3-catalog-/*/', 'mean')
    plt.plot(x_pos, catalog, label='catalog')
    node = http_metrics_series.get_data_points('puppet-v3-node-/*/', 'mean')
    plt.plot(x_pos, node, label='node')
    report = http_metrics_series.get_data_points('puppet-v3-report-/*/', 'mean')
    plt.plot(x_pos, report, label='report')
    file_metadatas = http_metrics_series.get_data_points('puppet-v3-file_metadatas-/*/', 'mean')
    plt.plot(x_pos, file_metadatas, label='file_metadatas')
    file_metadata = http_metrics_series.get_data_points('puppet-v3-file_metadata-/*/', 'mean')
    plt.plot(x_pos, file_metadata, label='file_metadata')

    # TODO: make x-axis use timestamps?
    plt.xlabel('Data points')
    plt.ylabel('Mean Response Time (ms)')
    plt.title('Mean Request Response Time')
    plt.legend(loc='upper left')
    plt.tight_layout()
    plt.show()