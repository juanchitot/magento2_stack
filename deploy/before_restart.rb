#!/usr/bin/env ruby
owner = new_resource.node["service"]["httpd"]["user"]
group = new_resource.node["service"]["httpd"]["group"]
Chef::Log.info "Chmod app directory to #{owner}:#{group}"
execute 'chown-files' do
  command "chown -R #{owner}:#{group} #{release_path}"
  not_if { owner.nil? or group.nil? }
end
shared_path = "#{@configuration[:deploy_to]}/shared"
execute 'chown-shared' do
  command "chown -R #{owner}:#{group} #{shared_path}"
  not_if { owner.nil? or group.nil? }
end
