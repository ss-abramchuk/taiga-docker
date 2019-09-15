#!/usr/bin/env ruby

require 'erb'

template_file = ARGV[0]
if template_file.nil?
  puts "Template file name was not provided."
  exit(false)
end

output_file = ARGV[1]
if output_file.nil?
  puts "Output file name was not provided."
  exit(false)
end

template_content = File.read(template_file)
erb_template = ERB.new(template_content, nil, "-")

result = erb_template.result
File.write(output_file, result)
