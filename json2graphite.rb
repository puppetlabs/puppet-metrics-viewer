#!/usr/bin/env ruby

require 'json'
require 'time'
require 'optparse'
require 'socket'
require 'net/http'
require 'uri'

class NetworkOutput
  # TODO: Support HTTPS.
  def initialize(host_url)
    @url = URI.parse(host_url) unless host_url.is_a?(URI)
    open
  end

  def open
    return if @output

    @output = case @url.scheme
              when 'tcp'
                TCPSocket.new(@url.host, @url.port)
              when 'http'
                http = Net::HTTP.new(@url.hostname, @url.port)
                http.keep_alive_timeout = 20
                http.start

                http
              end
  end

  def write(str, timeout = 1)
    case @url.scheme
    when 'tcp'
      begin
        @output.write(str)
      rescue Errno::EPIPE, Errno::EHOSTUNREACH, Errno::ECONNREFUSED
        close
        STDERR.puts "WARNING: write to #{@host} failed; sleeping for #{timeout} seconds and retrying..."
        sleep timeout
        open
        write(str, timeout * 2)
      end
    when 'http'
      request = Net::HTTP::Post.new(@url)
      request['Connection'] = 'keep-alive'
      response = @output.request(request, str)

      STDERR.puts "POST: #{@url} #{response.code}"
    end
  end

  def close
    case @url.scheme
    when 'tcp'
      @output.close
    when 'http'
      @output.finish
    end
  ensure
    @output = nil
  end
end

def parse_file(filename)
  data = JSON.parse(File.read(filename))

  # Newer versions of the log tool insert a timestamp field into the JSON.
  if data['timestamp']
    timestamp = Time.parse(data.delete('timestamp'))
    parent_key = nil
  else
    timestamp = get_timestamp(filename)
    # The only data supported in the older log tool comes from puppetserver.
    parent_key = 'servers.' + get_hoststr(filename) + '.puppetserver'
  end

  case $options[:output_format]
  when 'influxdb'
    influx_metrics(data, timestamp, parent_key).join("\n")
  else
    metrics(data, timestamp, parent_key).map do |item|
      item.split('\n')
    end.flatten.join("\r\n")
  end
end

def get_timestamp(str)
  # Example filename: nzxppc5047.nndc.kp.org-11_29_16_13:00.json
  timestr = str.match(/(\d\d)_(\d\d)_(\d\d)_(\d\d:\d\d)\.json$/) || raise("Unable to parse timestame from #{str}")
  yyyy = timestr[3].sub(/.*_(\d\d)$/, '20\1')
  mm = timestr[1]
  dd = timestr[2]
  hhmm = timestr[4]
  Time.parse("#{yyyy}-#{mm}-#{dd} #{hhmm}")
end

def get_hoststr(str)
  # Example filename: patched.nzxppc5047.nndc.kp.org-11_29_16_13:00.json
  str.match(/(patched\.)?([^\/]*)-(\d\d_){3}\d\d:\d\d\.json$/)[2].gsub('.', '-')
end

def safe_name(value)
  value.sub(/^[^0-9a-z_-]/i, '').gsub(/[^0-9a-z_-]/i, '_').gsub(/__/, '_').sub(/_*$/, '')
end

def array_cipher
  @array_cipher ||= {
    'http-metrics' => {
      'pkey' => 'route-id',
      'keys' => {
        'puppet-v3-catalog-/*/' => 'catalog',
        'puppet-v3-node-/*/'    => 'node',
        'puppet-v3-report-/*/'  => 'report',
        'puppet-v3-file_metadata-/*/'  => 'file-metadata',
        'puppet-v3-file_metadatas-/*/' => 'file-metadatas'
      }
    },
    'function-metrics' => {
      'pkey' => 'function',
      'keys' => :all
    }
  }
end

def error_name(str)
  if str["mbean"]
    str[/'[^']+'([^']+)'/,1]
  else
    str
  end
end

def return_tag(a, n)
  if a[n].is_a? String
    return a[n]
  else
    if n > -1
      return_tag(a, n-1)
    else return "none"
  end
end
end

def metrics(data, timestamp, parent_key = nil)
  data.collect do |key, value|
    current_key = [parent_key, safe_name(key)].compact.join('.')
    case value
    when Hash
      metrics(value, timestamp, current_key)
    when Array
      cipher = array_cipher[key]
      if cipher
        value.map do |elem|
          pkey_value = elem.delete(cipher['pkey'])
          elem.map do |k,v|
            if cipher['keys'] == :all || subkey = cipher['keys'][pkey_value]
              subkey ||= pkey_value
              "#{current_key}.#{safe_name(subkey)}.#{safe_name(k)} #{v} #{timestamp.to_i}"
            else
              nil
            end
          end.compact
        end.flatten.compact.join("\n")
      elsif key == 'error'
        value.map do |elem|
          ekey = error_name(elem)
          "#{current_key}.#{safe_name(ekey)} 1 #{timestamp.to_i}"
        end.compact
      else
        nil
      end
    else
      "#{current_key} #{value} #{timestamp.to_i}"
    end
  end.flatten.compact
end

def remove_trailing_comma(str)
    str.nil? ? nil : str.chomp(",")
end

def influx_tag_parser(tag)
  delete_set = ["status", "metrics", "routes", "status-service", "experimental", "app", "max", "min", "used", "init", "committed", "aggregate", "mean", "std-dev", "count", "total", "1", "5", "15"]
  tag = tag - delete_set
  tag_set = nil

  if tag.include? "servers"
    n = tag.index "servers"
    server_name = $options[:server_tag] || tag[n.to_i + 1]
    tag_set = "server=#{server_name},"
    tag.delete_at(tag.index("servers")+1)
    tag.delete("servers")
  end

  if tag.include? "orchestrator"
    tag_set = "#{tag_set}service=orchestrator,"
    tag.delete("orchestrator")
  end

  if tag.include? "puppet_server"
    tag_set = "#{tag_set}service=puppet_server,"
    tag.delete("puppet_server")
  end

  if tag.include? "puppetdb"
    tag_set = "#{tag_set}service=puppetdb,"
    tag.delete("puppetdb")
  end

  if tag.include? "gc-stats"
    n = tag.index "gc-stats"
    gcstats_name = tag[n.to_i + 1]
    tag_set = "#{tag_set}gc-stats=#{gcstats_name},"
    tag.delete_at(tag.index("gc-stats")+1)
    tag.delete("gc-stats")
  end

  if tag.include? "broker-service"
    n = tag.index "broker-service"
    brokerservice_name = tag[n.to_i + 1]
    tag_set = "#{tag_set}broker-service_name=#{brokerservice_name},"
    tag.delete_at(tag.index("broker-service")+1)
    tag.delete("broker-service")
  end

  if tag.length > 1
    measurement = tag.compact.join('.')
    tag_set = "#{measurement},#{tag_set}"
  elsif tag.length == 1
    measurement = tag[0]
    tag_set = "#{measurement},#{tag_set}"
  end

  tag_set = remove_trailing_comma(tag_set)
  return tag_set

end

def influx_metrics(data, timestamp, parent_key = nil)
  data.collect do |key, value|
    current_key = [parent_key, safe_name(key)].compact.join('.')
    case value
    when Hash
      influx_metrics(value, timestamp, current_key)
    when Numeric
      temp_key = current_key.split(".")
      field_key = return_tag(temp_key, temp_key.length)
      if field_key.eql? "none"
        break
      end
      field_value = value
      tag_set = influx_tag_parser(temp_key)
      "#{tag_set} #{field_key}=#{field_value} #{timestamp.to_i}"
    when Array
      # Puppet Profiler metric.
      pp_metric = case current_key
                  when /resource-metrics\Z/
                    "resource"
                  when /function-metrics\Z/
                    "function"
                  when /catalog-metrics\Z/
                    "metric"
                  when /http-metrics\Z/
                    "route-id"
                  else
                    # Skip all other array valued metrics.
                    next
                  end

      temp_key = current_key.split(".")
      tag_set = influx_tag_parser(temp_key)

      value.map do |metrics|
        working_set = metrics.dup
        entry_name = working_set.delete(pp_metric)
        next if entry_name.nil?

        # Strip characters reserved by InfluxDB.
        entry_name.gsub(/\s,=/, '')
        leader = "#{tag_set},name=#{entry_name}"

        measurements = working_set.map {|k,v| [k,v].join("=")}.join(',')

        "#{leader} #{measurements} #{timestamp.to_i}"
      end
    else
      nil
    end
  end.flatten.compact
end

$options = {}
OptionParser.new do |opt|
  opt.on('--pattern PATTERN') { |o| $options[:pattern] = o }
  opt.on('--netcat HOST') { |o| $options[:host] = o }
  opt.on('--port PORT')   { |p| $options[:port] = p }
  opt.on('--convert-to FORMAT') { |o| $options[:output_format] = o }
  opt.on('--server-tag SERVER_NAME') { |o| $options[:server_tag] = o }

  # InfluxDB options
  opt.on('--influx-db DATABASE_NAME') {|o| $options[:influx_db] = o }
end.parse!

if $options[:host]
  url = case $options[:output_format]
        when 'influxdb'
          raise ArgumentError, "--influx-db must be passsed along with --netcat" unless $options[:influx_db]
          port = $options[:port] || "8086"
          "http://#{$options[:host]}:#{port}/write?db=#{$options[:influx_db]}&precision=s"
        else
          port = $options[:port] || "2003"
          "tcp://#{$options[:host]}:#{port}"
        end

  $net_output = NetworkOutput.new(url)
end

data_files = ARGV
data_files += Dir.glob($options[:pattern]) if $options[:pattern]

data_files.each do |filename|
  begin
    converted_data = parse_file(filename)

    if $options[:host]
      $net_output.write(converted_data)
    else
      STDOUT.write(converted_data)
    end
  rescue => e
    STDERR.puts "ERROR: #{filename}: #{e.message}"
  end
end

$net_output.close if $options[:host]
