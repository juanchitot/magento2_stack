
class DbCommand
    def initialize(user, password, host,database)
        @username = user
        @password = password
        @host = host
        @database = database
        @command = "mysql -u #{@username} -p#{@password} -h #{@host} #{@database}"
    end

    def run(command)
        output = `#{@command} -e "#{command}"`
        if (output == "") or (not $?.success?)
            return false
        end
        return true
    end

    def checkDBExists()
        output = `#{@command} -e "show tables like 'core_config_data'"`
        if (output == "") or (not $?.success?)
            return false
        end
        return true
    end

    def updateCoreConfigData(path,value,scope=nil)
        cmd = "#{@command} -e \"UPDATE core_config_data set value = '#{value}' where path = '#{path}' "
        if /^[a-z]+$/.match(scope.to_s)
            cmd += " and scope = '#{scope}' \" "
        elsif /^[0-9]+$/.match(scope.to_s)
            cmd += " and scope_id = '#{scope}' \" "
        else
            cmd += " \" "
        end
        output = `#{cmd}`
        if (output == "") or (not $?.success?)
            return false
        end
        return true
    end
end