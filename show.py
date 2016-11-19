import matplotlib.pyplot as plt
import seaborn as sns
import json
from pprint import pprint
import os
import numpy as np

# Set default Seaborn style
sns.set()

data_dir = ".."
data_file_path = os.path.join(data_dir, "oser501990.wal-mart.com-11_18_16_20:15.json");

with open(data_file_path) as data_file:
    data = json.load(data_file)


pprint(data['pe-master']['status']['experimental']['http-metrics'])

http_metrics = data['pe-master']['status']['experimental']['http-metrics']
http_metrics = filter(lambda x: x['route-id'] != 'total', http_metrics)
max_aggregate = max(map(lambda x: x['aggregate'], http_metrics))
cutoff = max_aggregate / 10000.0
http_metrics = filter(lambda x: x['aggregate'] > cutoff, http_metrics)


requests = map(lambda x: x['route-id'], http_metrics)
y_pos = np.arange(len(requests))
aggregate = map(lambda x: x['aggregate'], http_metrics)

plt.barh(y_pos, aggregate, align='center', alpha=0.5)
plt.yticks(y_pos, requests)
plt.ylabel('HTTP Endpoints')
plt.xlabel('Response time (ms)')
plt.title('Aggregate Request Response Time')
plt.tight_layout()
plt.show()