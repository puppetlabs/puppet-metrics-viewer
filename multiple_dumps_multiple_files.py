import json
import argparse
import os

import puppetserver_metrics_viz.http as http
import puppetserver_metrics_viz.mem as mem
import puppetserver_metrics_viz.jruby as jruby

# TODO: this code was written to import data from the one-file-per-status-request
#  layout that is done via Nick Walker's puppet module (via cron).  Newer versions
#  of tk-status have a setting that you can use to collect the same data at a
#  specified time interval, but they will just append each subsequent data set
#  to a single file.  I'm envisioning a refactor of this code that moves the
#  graphing logic to a common, re-usable location, and then the logic in this file
#  would just be responsible for parsing the input file(s) and handing off the
#  graphing work to that code.  Then we can add a second version of this CLI
#  script that knows how to read the tk-status format, where the data is all in
#  one file.

parser = argparse.ArgumentParser(description='Produce visualizations for a series of JSON metrics dumps.')
requiredNamed = parser.add_argument_group('required named arguments')
requiredNamed.add_argument('--file-prefix',
                           help='File path prefix for files containing metrics data.  All files existing at the specified path that begin with this prefix will be loaded, in order by filename.',
                           required=True)
args = parser.parse_args()

prefix = args.file_prefix

dir = os.path.dirname(prefix)
file_prefix = os.path.basename(prefix)

files = filter(lambda f: f.startswith(file_prefix), os.listdir(dir))
files.sort()
files = map(lambda f: os.path.join(dir, f), files)

def read_data(f):
    with open(f) as data_file:
        return json.load(data_file)

data = map(read_data, files)

# TODO: refactor this logic into a class to make it more re-usable

http_mean_img = 'http_mean.png'
## Commented out count and aggregate for now because they aren't really that useful
# http_aggregate_img = 'http_aggregate.png'
# http_count_img = 'http_count.png'
memory_usage_img = 'memory_usage.png'
jruby_borrow_img = 'jruby_borrow_times.png'
jruby_instances_img = 'jruby_instances.png'

http_metrics_series = http.HttpMetricsSeries(data)
http.multi_datapoint_line_graph(http_metrics_series,
                                {'data_field': 'mean',
                                 'data_label': 'Mean',
                                 'img_file': './target/{0}'.format(http_mean_img)})
## Commented out count and aggregate for now because they aren't really that useful
# http.multi_datapoint_line_graph(http_metrics_series,
#                                 {'data_field': 'aggregate',
#                                  'data_label': 'Aggregate',
#                                  'img_file': './target/{0}'.format(http_aggregate_img)})
# http.multi_datapoint_line_graph(http_metrics_series,
#                                 {'data_field': 'count',
#                                  'data_label': 'Count - ',
#                                  'img_file': './target/{0}'.format(http_count_img)})

memory_metrics_series = mem.MemoryMetricsSeries(data)
mem.multi_datapoint_line_graph(memory_metrics_series,
                               {'img_file': './target/{0}'.format(memory_usage_img)})

jruby_metrics_series = jruby.JRubyMetricsSeries(data)
jruby.multi_datapoint_line_graph(jruby_metrics_series,
                               {'img_file': './target/{0}'.format(jruby_borrow_img),
                                'metrics': ['average_borrow_time', 'average_wait_time'],
                                'title': "JRuby Borrow Times",
                                'y-label': "Time (ms)"})
jruby.multi_datapoint_line_graph(jruby_metrics_series,
                                 {'img_file': './target/{0}'.format(jruby_instances_img),
                                  'metrics': ['average_free_jrubies', 'average_requested_jrubies'],
                                  'title': "Free / Requested JRuby Instances",
                                  'y-label': "Num JRuby instances"})

# TODO: gussie up

html_file = './target/report.html'
with open(html_file, 'w') as out:
    out.write('''
       <html>
          <table>
            <tr>
               <td><img src="{0}"/></td>
               <td><img src="{1}"/></td>
            </tr>
            <tr>
               <td><img src="{2}"/></td>
               <td><img src="{3}"/></td>
            </tr>
          </table>
       </html>
    '''.format(http_mean_img, memory_usage_img, jruby_borrow_img, jruby_instances_img))


