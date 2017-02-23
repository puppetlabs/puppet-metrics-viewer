#!/usr/bin/env ruby

require 'json'
require 'time'
require 'optparse'

def parse_file(filename)
  begin
    data = JSON.parse(File.read(filename))
    puts metrics(data, get_timestamp(filename), 'servers.' + get_hoststr(filename))
  rescue Exception => e
    STDERR.puts "ERROR: #{filename}: #{e.message}"
  end
end

def get_timestamp(str)
  # Example filename: nzxppc5047.nndc.kp.org-11_29_16_13:00.json
  timestr = str.match(/(\d\d)_(\d\d)_(\d\d)_(\d\d:\d\d)\.json$/)
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
  value.sub(/^[^0-9a-z_]/i, '').gsub(/[^0-9a-z_]/i, '_').gsub(/__/, '_').sub(/_*$/, '')
end

def array_element_pkey(element)
  case element
  when 'function-metrics'; 'function'
  when 'resource-metrics'; 'resource'
  when 'http-metrics'; 'route-id'
  else
    nil
  end
end

def metrics(data, timestamp, parent_key = nil)
  data.collect do |key, value|
    current_key = [parent_key, safe_name(key)].compact.join('.')
    case value
    when Hash
      metrics(value, timestamp, current_key)
    when Array
      pkey = array_element_pkey(key)
      if pkey
        value.map do |elem|
          pkey_value = elem.delete(pkey)
          elem.map do |k,v|
            "#{current_key}.#{safe_name(pkey_value)}.#{safe_name(k)} #{v} #{timestamp.to_i}"
          end
        end.join("\n")
      else
        nil
      end
    else
      "#{current_key} #{value} #{timestamp.to_i}"
    end
  end.flatten.compact
end

options = {}
OptionParser.new do |opt|
  opt.on('--pattern PATTERN') { |o| options[:pattern] = o }
end.parse!

if options[:pattern]
  Dir.glob(options[:pattern]).each do |filename|
    parse_file(filename)
  end
end

while filename = ARGV.shift
  parse_file(filename)
end
