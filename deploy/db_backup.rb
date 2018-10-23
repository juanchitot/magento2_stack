require 'rubygems'
require 'pathname'
require 'date'
require 'open3'

# TODO: Improve argument passing
bucket = ARGV[0]
basePath = ARGV[1]
database = "shop"

current_dir = Pathname.new(File.dirname(__FILE__)).realpath

now = DateTime.now
date = now.strftime('%Y-%d-%m')
filename = "#{date}-#{database}.sql.gz"
local_file = "#{current_dir}/#{filename}"
upload = true

puts 'Creating new backup...'
dump_command = "#{basePath}/shell/db_dump.sh -dzDAf #{local_file} -w #{basePath}"
print dump_command
unless system(dump_command)
  upload = false
end

# Normalize month
month = '%02i' % now.month

if upload
  puts 'Dump finished, uploading..'

  upload_command = "/usr/local/bin/aws s3 cp #{local_file} s3://#{bucket}/#{database}/#{now.year}/#{month}/#{filename}"
  stdout_str, stderr_str, status = Open3.capture3(upload_command)
  if status.success?
    puts 'SUCCESS: Uploaded successfully!'
        print stdout_str
  else
    puts "ERROR: Couldn't upload"
        print stderr_str
  end
  system("rm #{local_file}")
end
