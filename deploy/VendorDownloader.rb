require 'rubygems'
require 'pathname'
require 'date'
require 'open3'

# TODO: Improve argument passing
bucket = ARGV[0]
basePath = ARGV[1]
database = "shop"

current_dir = Pathname.new(File.dirname(__FILE__)).realpath


def parseS3ListLine(line)
	mtch =  /vendor_([\d]{4})_([\d]{2})_([\d]{2})_([\d]{2})_([\d]{2})_([\d]{2}).zip.*/.match line
        if mtch
			data =  {
				"filename" => "vendor_#{mtch[1]}_#{mtch[2]}_#{mtch[3]}_#{mtch[4]}_#{mtch[5]}_#{mtch[6]}.zip" , 
				"created" =>  DateTime.new(	mtch[1].to_i,
											mtch[2].to_i,
											mtch[3].to_i,
											mtch[4].to_i,
											mtch[5].to_i,
											mtch[6].to_i) 
			}
       		return data
	end
	return nil
end

def findFile (bucket,filterCode=nil, sort=nil, limit=nil) 
  list_command = "/usr/local/bin/aws s3  ls #{bucket}"
  stdout_str, stderr_str, status = Open3.capture3(list_command)
  if status.success?
	data = [nil]
        lines = stdout_str.split /$/ 
	lines.each do | l | 
 		 data.push(parseS3ListLine l)
	end
	sorted =  data.compact.sort { |x,y| x['created'] <=> y['created']  }
	puts sorted
	
	if sorted.size 
		print "Se encontro el file #{sorted.last['filename']}"
		return sorted.last
	end
	return nil
  else
    puts "ERROR: Couldn't upload"
        print stderr_str
  end
	return nil
end




def downloadVendorFile(remoteFile,localFile)
	download_command = "/usr/local/bin/aws s3 cp #{remoteFile} #{localFile}"
	print download_command
	stdout_str, stderr_str, status = Open3.capture3(download_command)
	if status.success?
	    puts 'SUCCESS: Downloaded successfully!'
	    print stdout_str  
		return true
	else
	    puts "ERROR: Couldn't download"
	        print stderr_str
	end
	return false
end


def uncompressVendor(what, where)
	system("unzip -ud #{where} #{what}")	
end


local_file = '/tmp/vendor.zip'
#bucket "s3://usps-m2-webroot-deploy/"
vendor_file = findFile bucket 
if !vendor_file.nil?
	if downloadVendorFile("#{bucket}#{vendor_file['filename']}",local_file)
		uncompressVendor(local_file,basePath)
                print "Se instalo el file vendor  #{vendor_file['filename']}"
	end
end

#download_command = "/usr/local/bin/aws s3 cp #{bucket}#{vendor_file['filename']} #{local_file}"
