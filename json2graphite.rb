#!/usr/bin/env ruby

require 'json'
require 'time'

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

def metrics(data, timestamp, parent_key = nil)
  data.collect do |key, value|
    current_key = [parent_key, key].compact.join('.')
    case value
    when Hash
      metrics(value, timestamp, current_key)
    when Array
      # Not implemented; we simply won't include these metrics in the export
      nil
    else
      "#{current_key} #{value} #{timestamp.to_i}"
    end
  end.flatten.compact
end

while filename = ARGV.shift
  begin
    data = JSON.parse(File.read(filename))
    puts metrics(data, get_timestamp(filename), 'servers.' + get_hoststr(filename))
  rescue Exception => e
    STDERR.puts "ERROR: #{filename}: #{e.message}"
    next
  end
end
