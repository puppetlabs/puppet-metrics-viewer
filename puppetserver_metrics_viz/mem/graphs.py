import matplotlib.pyplot as plt
import numpy as np
import time

def multi_datapoint_line_graph(memory_metrics_series, config):
    plt.clf()

    x_pos = np.arange(len(memory_metrics_series))
    img_file = config['img_file']

    x_labels = map(lambda x: time.strftime('%H:%M:%S', time.localtime(x)),
                   memory_metrics_series.get_timestamps())
    heap_max = memory_metrics_series.get_data_points('heap', 'max')
    plt.plot(x_pos, heap_max, label='Heap - Max')
    heap_init = memory_metrics_series.get_data_points('heap', 'init')
    plt.plot(x_pos, heap_init, label='Heap - Init')
    heap_committed = memory_metrics_series.get_data_points('heap', 'committed')
    plt.plot(x_pos, heap_committed, label='Heap - Committed')
    heap_used = memory_metrics_series.get_data_points('heap', 'used')
    plt.plot(x_pos, heap_used, label='Heap - Used')

    plt.xlabel('Data points')
    plt.xticks(x_pos, x_labels)
    plt.locator_params(axis='x', nbins=10)
    plt.ylabel('Memory Usage (MB)')
    plt.title('Memory Usage')
    plt.legend(loc='upper left')
    plt.tight_layout()
    plt.savefig(img_file)