FROM grafana/grafana
MAINTAINER Reid Vandewiele <reid@puppet.com>
USER root

USER root

COPY build/* /grafana-puppet/
RUN apk add curl && \
    rm -rf /tmp/*

USER grafana

ENTRYPOINT /grafana-puppet/run.sh

LABEL org.label-schema.vendor="Reid Vandewiele" \
      org.label-schema.name="Grafana Puppetserver Dashboard" \
      org.label-schema.description="Grafana running a dashboard to display puppetserver metrics captured using npwalker/pe_metric_curl_cron_jobs" \
      org.label-schema.version="1.8.0" \
      org.label-schema.vcs-url="https://github.com/puppetlabs/puppet-metrics-viewer" \
      org.label-schema.build-date="2017-05-26" \
      org.label-schema.docker.schema-version="1.0"
