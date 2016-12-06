
import puppetserver_metrics_viz.http as http
import puppetserver_metrics_viz.mem as mem
import puppetserver_metrics_viz.jruby as jruby


class Graphs:
    @staticmethod
    def generate_graphs(data):
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
