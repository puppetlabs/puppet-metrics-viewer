import matplotlib.pyplot as plt
import numpy as np
import time

def multi_datapoint_line_graph(jruby_metrics_series, config):
    plt.clf()

    x_pos = np.arange(len(jruby_metrics_series))
    img_file = config['img_file']

    x_labels = map(lambda x: time.strftime('%H:%M:%S', time.localtime(x)),
                   jruby_metrics_series.get_timestamps())

    metrics = config['metrics']
    for metric in metrics:
        data_points = jruby_metrics_series.get_data_points(metric)
        plt.plot(x_pos, data_points, label=metric)

    plt.xlabel('Data points')
    plt.xticks(x_pos, x_labels)
    plt.locator_params(axis='x', nbins=10)
    plt.ylabel(config['y-label'])
    plt.title(config['title'])
    plt.legend(loc='upper left')
    plt.tight_layout()
    plt.savefig(img_file)