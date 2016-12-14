#!/usr/bin/env ruby

require 'time'
require 'json'

start_time = nil

def get_timestamp(str)
  # Example filename: nzxppc5047.nndc.kp.org-11_29_16_13:00.json
  timestr = str.match(/((\d\d_?){3})_(\d\d:\d\d)/)
  yyyy = timestr[1].sub(/.*_(\d\d)$/, '20\1')
  mm = timestr[1].match(/^(\d\d)/)[1]
  dd = timestr[1].match(/_(\d\d)_/)[1]
  hhmm = timestr[3]

  Time.parse("#{yyyy}-#{mm}-#{dd} #{hhmm}").to_i * 1000
end

while filename = ARGV.shift
  metrics = JSON.parse(File.read(filename))
  timestamp = get_timestamp(filename)
  new_data = {
    "status-service" => {
      "status" => {
        "experimental" => {
          "jvm-metrics" => {
            "start-time-ms" => 0,
            "up-time-ms" => timestamp,
            "heap-memory" => {
              "committed" => 0,
              "max" => 0,
              "used" => 0,
              "init" => 0
            },
            "non-heap-memory" => {
              "committed" => 0,
              "max" => 0,
              "used" => 0,
              "init" => 0
            }}}}}}
  new_filename = filename.sub(/(#{File.basename(filename)}$)/, 'patched.\1')
  puts "new filename: #{new_filename}"
  File.open(new_filename, 'w') do |file|
    file.write JSON.pretty_generate(new_data.merge(metrics))
  end
end
