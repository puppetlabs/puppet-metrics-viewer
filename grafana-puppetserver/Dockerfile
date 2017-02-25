FROM grafana/grafana
MAINTAINER Reid Vandewiele <reid@puppet.com>

COPY build/* /grafana-puppet/
RUN apt-get update && apt-get install -y curl
ENTRYPOINT /grafana-puppet/run.sh

LABEL org.label-schema.vendor="Reid Vandewiele" \
      org.label-schema.name="Grafana Puppetserver Dashboard" \
      org.label-schema.description="Grafana running a dashboard to display puppetserver metrics captured using npwalker/pe_metric_curl_cron_jobs" \
      org.label-schema.version="1.2.0" \
      org.label-schema.vcs-url="https://github.com/puppetlabs/puppetserver-metrics-viz" \
      org.label-schema.build-date="2017-02-23" \
      org.label-schema.docker.schema-version="1.0"
