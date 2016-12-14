## puppetserver-metrics-viz

![screenshot](./metrics_viz.jpg)

This repo contains some CLI tools for generating visualizations of puppetserver
metrics data.  It assumes that you have collected one or more JSON payloads
from the PE Puppet Server status endpoint and saved them to disk.

The current implementation supports visualizing data produced by Nick Walker's
puppet module / cron job, where there are periodic HTTP requests made to the
status endpoint and each result is saved to a unique file with a predictable
naming convention.  The code is organized such that it should be easy to add
another CLI tool that will allow you to generate the same visualizations based
on data produced via the `debug-logging` setting in tk-status (see
[TK-400](https://tickets.puppetlabs.com/browse/TK-400 for more info), which
takes the approach of appending each HTTP response to a single file rather
than splitting over multiple files.

To run this code, you will need the following python-related distro packages:

```
python-tk
python-setuptools
python-wheel
```

Then you will need to install the following python libraries:

```
pip install seaborn numpy matplotlib
```

After that, you can run the script `multiple_dumps_multiple_files.py`, passing
it the prefix of the series of files you want it to generate visualizations
for.  e.g.:

```
python ./multiple_dumps_multiple_files.py --file-prefix ./target/pe_metrics/puppet_server/my.host.name-11_18_16
```

The results are currently written to the `./target` directory - open up
`report.html` in your browser.

### Metrics from Older PE Installations

Some older installations of PE (e.g. 2016.1.2) do not log data expected by the visualizer scripts. As a work-around, you can run the included `patch_files.rb` script to create versions of the json files with injected dummy data, so that they can be processed and visualized anyway.

Usage:

    ./patch_files.rb [filename_1 ... filename_n]

Example:

    ./patch_files.rb ~/Downloads/wells_fargo/puppet_server/*.json

The tool will create new files alongside the originals with the prefix "patched."

### TODO LIST

* use different output dirs / filenames based on the input so you don't blow away
  your previous results when you run the tool
* Add some output indicating where the files were written
* Add support for additional Puppet Server metrics
* Add support for other service's metrics (e.g. PuppetDB)
