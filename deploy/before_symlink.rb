#!/usr/bin/env ruby
require 'yaml'
require "#{::File.expand_path(::File.dirname(__FILE__))}/app_config_generator"
require "#{::File.expand_path(::File.dirname(__FILE__))}/db_command"
require 'json'
package  'composer'
# @node = run_context.node
#app_env = @node[:strategery][:app_env] || 'development'
app_env =  'development'
environment_data = new_resource.environment

if ! environment_data['environment'].nil?
  app_env = environment_data['environment']
end
# app = (@configuration[:params][:deploy_data]['application'] || 'shop').to_sym

# deploy_resource = new_resource
# file '/tmp/node_new_resource.json' do
#   content YAML::dump(new_resource)
# end

app_current_path = "#{@configuration[:deploy_to]}/current"
shared_path = "#{@configuration[:deploy_to]}/shared"

# # Set sticky bit to directories

# file "#{shared_path}/var/.htaccess" do
#   content "Order Deny,Allow\nDeny from all"  
# end


# # Chef::Log.info 'Ensuring proper file permissions'
owner = new_resource.node["service"]["httpd"]["user"]
group = new_resource.node["service"]["httpd"]["group"]

# # Set sticky bit to directories
execute 'chmod-directories' do
	command "find #{release_path} -type d -exec chmod +s {} \\;"
end

# # Change file permissions
# Chef::Log.info 'Ensuring proper file permissions'
execute 'chmod-files' do
	command "chmod -R g+w #{release_path}"
end
execute 'copy-pub/media-data' do
	command "cp -ar #{release_path}/pub/media/. #{shared_path}/media/ && rm -rdf #{release_path}/pub/media"

end

link "#{release_path}/pub/media" do
   to "#{shared_path}/media/"
end



#./bin/magento setup:install --db-host="eplc-m2-db.c8kmmg97boiq.us-east-1.rds.amazonaws.com" --db-user="eplc_m2_user" --db-password='P4E3!_-Oo0' --backend-frontname="admin_esn5f4" --db-name=shop --admin-user=juan.medina.raco --admin-password=Juancho1234 --admin-firstname=juan --admin-lastname=Medina --admin-email=juan.medin.raco@gmail.com


#./bin/magento setup:config:set --db-host="eplc-m2-db.c8kmmg97boiq.us-east-1.rds.amazonaws.com" --db-user="eplc_m2_user" --db-password='P4E3!_-Oo0' --backend-frontname="admin_esn5f4" --db-name=shop

######################
#execute 'composer-install' do
#  command "composer install"
#  cwd "#{release_path}"
#end
execute 'chmod-bin-magento' do
	command "chmod +x #{release_path}/bin/magento"
end

######################

# execute 'compile-scss' do
#   command "compass compile #{release_path}/skin/frontend/zmc/default/scss"
# end

# create shared/ directory structure and symlinks
# Chef::Log.info 'Symlinking sitemaps'

# directory "#{release_path}/efiresupply" do
#   recursive true
#   mode '0777'
#   owner owner
# end
# directory "#{shared_path}/sitemaps/efiresupply" do
#   recursive true
#   mode '0777'
#   owner owner
#   not_if "test -d #{shared_path}/sitemaps/efiresupply"
# end
# link "#{release_path}/sitemaps" do
#   to "#{shared_path}/sitemaps"
# end 
# link "#{release_path}/sitemap.xml" do
#   to "#{shared_path}/sitemaps/sitemap.xml"
# end 
# link "#{release_path}/efiresupply/sitemap.xml" do
#   to "#{shared_path}/sitemaps/efiresupply/sitemap.xml"
# end 

### Database Updates

# DBC = DbCommand.new(environment_data['db_user'],environment_data['db_password'],environment_data['address'],'shop')
# if not DBC.checkDBExists()
#     Chef::Application.fatal!("There is no database! dying")
# end

# domain = environment_data['domain']
# cookie_domain = new_resource.node[:strategery][:cookie_domain] || ".#{domain}"
# varnish_secret =  new_resource.node[:varnish][:secret]

# if app_env == 'development' 

#   {:unsecure => :https, :secure => :https }.each_pair do |security,protocol |
#       DBC.updateCoreConfigData("web/#{security}/base_url","#{protocol}://#{domain}/",'default')
#   end
  
#   DBC.updateCoreConfigData("web/cookie/cookie_domain",cookie_domain,'default')
#   DBC.updateCoreConfigData("turpentine_varnish/servers/auth_key",varnish_secret)
#   DBC.updateCoreConfigData("web/secure/offloader_header","HTTP_SSL_OFFLOADED")
#   DBC.updateCoreConfigData("web/cookie/cookie_path","/",'default')
#   DBC.updateCoreConfigData("system/smtp/disable","1")  
#   DBC.updateCoreConfigData("design/head/demonotice","1")    
# end


# #### Generate local.xml
# CG = ConfigGenerator.new("#{release_path}/app/etc/local.xml.#{app_env}.template")
# CG.generate({
#     :user => environment_data['db_user'],
#     :password => environment_data['db_password'],
#     :host => environment_data['address'],
#     :database => 'shop'
#   }, "#{release_path}/app/etc/local.xml"
# )
##############################################
ruby_block 'install vendendor' do
        block do
            vendor_command = "ruby #{release_path}/deploy/VendorDownloader.rb '#{environment_data['vendor_bucket']}'  '#{release_path}'"
            stdout_str, stderr_str, status = Open3.capture3(vendor_command)
              if status.success?
                    Chef::Log.info "#{stdout_str}"			            
              else
                    Chef::Log.info "#{stderr_str}"			
              end                
        end
        action :run
end

#execute 'install-vendor' do
#  command 
#  live_stream true
#  cwd "#{release_path}"
#end
execute 'enable-modules' do
  command "#{release_path}/bin/magento  module:enable --all"
  cwd "#{release_path}"
end

execute 'di-compile' do
  command "#{release_path}/bin/magento  setup:di:compile"
  cwd "#{release_path}"
end

execute 'set-database' do
  command "#{release_path}/bin/magento  setup:config:set --db-host='#{environment_data['address']}' --db-user='#{environment_data['db_user']}' --db-password='#{environment_data['db_password']}' --backend-frontname='epoliceadmin500A' --db-name=shop"
   cwd "#{release_path}"
end


execute 'hack_magento_install' do
  command "php #{release_path}/deploy/install_hack.php" 
  cwd "#{release_path}/deploy"
end

execute 'deploy_static_content' do
  command "#{release_path}/bin/magento setup:static-content:deploy en_US" 
  cwd "#{release_path}/deploy"
  ignore_failure true
end




# execute 'update-var' do
#   command "cp -rf #{release_path}/var/*  #{shared_path}/var/ && cp -f #{release_path}/var/.htaccess  #{shared_path}/var"
#   ignore_failure true
# end

# execute 'removes-chkout-var' do
#   command "rm -rdf #{release_path}/var"
# end
##############################################


#### Link to appropriate robots.txt file
#Chef::Log.info "Symlinking local.xml.#{app_env}"
#link "#{release_path}/robots.txt" do
#  to "#{release_path}/robots.txt.#{app_env}"
#end


### CRON

#if app_env == 'production'
#    cron 'Shop - DB Backup' do
#      minute '0'
#      hour '3' # 3AM UTC / 11PM EST
#      command "ruby #{app_current_path}/deploy/db_backup.rb #{node[:strategery][:backups][:database_bucket]} #{release_path}  >> #{release_path}/../../shared/logs/db_backup_crontab.log"
#    end

#    cron 'Media Backup' do
#          minute '0'
#          hour '4' # 4AM UTC / 12PM EST
#          weekday '1' # On Mondays
#          command "ruby #{app_current_path}/deploy/media_backup.rb #{node[:strategery][:backups][:media_bucket]}  #{release_path}/../../shared/media >> #{release_path}/../../shared/logs/media_backup_crontab.log"
#    end
#end

#cron 'Magento Cron' do
#  minute '*/5'
#  command "#{release_path}/cron.sh >> #{release_path}/../../shared/logs/mage_crontab.log"
#  user owner.nil? ? 'root' : owner
#end

# cron 'Sooqr Epolice Cron' do
#   minute '30'
#   hour '4'
#   command "env php #{release_path}/app/code/community/Sooqr/Feed/scripts/generate_sooqr_feed.php default >> #{release_path}/../../shared/logs/sooqr_crontab.log 2>&1"
#   user owner.nil? ? 'root' : owner
# end

# cron 'Sooqr Efire Cron' do
#   minute '30'
#   hour '3'
#   command "env php #{release_path}/app/code/community/Sooqr/Feed/scripts/generate_sooqr_feed.php fire >> #{release_path}/../../shared/logs/sooqr_crontab.log 2>&1"
#   user owner.nil? ? 'root' : owner
# end
