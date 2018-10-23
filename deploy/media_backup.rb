require 'rubygems'
require 'pathname'
require 'date'
require 'open3'

# TODO: Improve argument passing
bucket = ARGV[0]
mediaFolder = ARGV[1]
site="shop"

current_dir = Pathname.new(File.dirname(__FILE__)).realpath

now = DateTime.now
date = now.strftime('%Y-%d-%m')
filename = "#{date}-media.tar.gz"
local_file = "#{current_dir}/#{filename}"


puts 'Captcha folder cleanup'
clean_command = "find #{mediaFolder}/captcha/ -regextype posix-extended -iregex '.*/[a-z0-9]+\.png' -mtime +1 -delete  "
print clean_command
system(clean_command)


upload = true
puts 'Creating new backup...'
dump_command = "tar -cf #{local_file} --exclude='cache' --exclude='captcha' #{mediaFolder}"
print dump_command

unless system(dump_command)
  upload = false
end

# Normalize month
month = '%02i' % now.month

if upload
  puts 'Dump finished, uploading..'
  upload_command = "/usr/local/bin/aws s3 cp #{local_file} s3://#{bucket}/#{site}/#{now.year}/#{month}/#{filename}"
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
