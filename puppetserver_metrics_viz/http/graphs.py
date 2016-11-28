import matplotlib.pyplot as plt
import numpy as np
import time

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


def multi_datapoint_line_graph(http_metrics_series, config):
    plt.clf()

    x_pos = np.arange(len(http_metrics_series))
    data_field = config['data_field']
    data_label = config['data_label']
    img_file = config['img_file']

    x_labels = map(lambda x: time.strftime('%H:%M:%S', time.localtime(x)),
                   http_metrics_series.get_timestamps())
    catalog = http_metrics_series.get_data_points('puppet-v3-catalog-/*/', data_field)
    plt.plot(x_pos, catalog, label='catalog')
    node = http_metrics_series.get_data_points('puppet-v3-node-/*/', data_field)
    plt.plot(x_pos, node, label='node')
    report = http_metrics_series.get_data_points('puppet-v3-report-/*/', data_field)
    plt.plot(x_pos, report, label='report')
    file_metadatas = http_metrics_series.get_data_points('puppet-v3-file_metadatas-/*/', data_field)
    plt.plot(x_pos, file_metadatas, label='file_metadatas')
    file_metadata = http_metrics_series.get_data_points('puppet-v3-file_metadata-/*/', data_field)
    plt.plot(x_pos, file_metadata, label='file_metadata')

    plt.xlabel('Data points')
    plt.xticks(x_pos, x_labels)
    plt.locator_params(axis='x', nbins=10)
    plt.ylabel('{0} Response Time (ms)'.format(data_label))
    plt.title('{0} Request Response Time'.format(data_label))
    plt.legend(loc='upper left')
    plt.tight_layout()
    plt.savefig(img_file)