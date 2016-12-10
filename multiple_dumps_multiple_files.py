import json
import argparse
import os

from puppetserver_metrics_viz.common.graphs import Graphs

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
    print "Parsing file: '{0}'".format(f)
    with open(f) as data_file:
        return json.load(data_file)

data = map(read_data, files)

Graphs.generate_graphs(data)