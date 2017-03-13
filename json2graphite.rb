#!/usr/bin/env ruby

require 'json'
require 'time'
require 'optparse'
require 'socket'

class Nc
  def initialize(host)
    @host = host
  end

  def socket
    return @socket if @socket && !@socket.closed?
    @socket = TCPSocket.new(@host, 2003)
  end

  def write(str, timeout = 1)
    begin
      socket.write("#{str}\r\n")
    rescue Errno::EPIPE, Errno::EHOSTUNREACH, Errno::ECONNREFUSED
      @socket = nil
      STDERR.puts "WARNING: write to #{@host} failed; sleeping for #{timeout} seconds and retrying..."
      sleep timeout
      write(str, timeout * 2)
    end
  end

  def close_socket
    @socket.close if @socket
    @socket = nil
  end
end

def parse_file(filename)
  nc = nil
  if $options[:host]
    nc = Nc.new($options[:host])
  end
  begin
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

    array = metrics(data, timestamp, parent_key)
    lines = array.map do |item|
      item.split('\n')
    end.flatten

    lines.each do |line|
      if nc
        # IS THIS NECESSARY??? I HAVE NO IDEA!!!
        #sleep 0.0001
        nc.write("#{line}\n")
      else
        puts(line)
      end
    end
  rescue Exception => e
    STDERR.puts "ERROR: #{filename}: #{e.message}"
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
      else
        nil
      end
    else
      "#{current_key} #{value} #{timestamp.to_i}"
    end
  end.flatten.compact
end

$options = {}
OptionParser.new do |opt|
  opt.on('--pattern PATTERN') { |o| $options[:pattern] = o }
  opt.on('--netcat HOST') { |o| $options[:host] = o }
end.parse!

if $options[:pattern]
  Dir.glob($options[:pattern]).each do |filename|
    parse_file(filename)
  end
end

while filename = ARGV.shift
  parse_file(filename)
end
