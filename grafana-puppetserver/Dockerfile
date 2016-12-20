FROM grafana/grafana
MAINTAINER Reid Vandewiele <reid@puppet.com>

COPY volumes/grafana/var/grafana.db /var/lib/grafana/grafana.db

LABEL org.label-schema.vendor="Reid Vandewiele" \
      org.label-schema.name="Grafana Puppetserver Dashboard" \
      org.label-schema.description="Grafana running a dashboard to display puppetserver metrics captured using npwalker/pe_metric_curl_cron_jobs" \
      org.label-schema.version="1.0.0" \
      org.label-schema.vcs-url="https://github.com/puppetlabs/puppetserver-metrics-viz" \
      org.label-schema.build-date="2016-12-22" \
      org.label-schema.docker.schema-version="1.0"
