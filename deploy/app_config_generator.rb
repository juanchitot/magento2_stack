require "erb"

class TemplateGenerator_
  def initialize(user, password, host,database)
    @username = user
    @password = password
    @host = host
    @database = database
  end
end

class ConfigGenerator
	def initialize (template)
		@erb = ERB.new(File.read(template))
		@erb.filename = template
		@TemplateGenerator = @erb.def_class(TemplateGenerator_, 'render()')
	end

	def generate (vars, outputfile)
		print vars
		output = @TemplateGenerator.new(vars[:user], vars[:password], vars[:host],vars[:database]).render()
		File.open(outputfile, 'w') { |file| file.write(output) }
	end
end

# CG = ConfigGenerator.new("../app/etc/local.xml.production")
# CG.generate({
# 		:user => "myUser",
# 		:password => "myPassword",
# 		:host => "myHost",
# 		:database => "myDatabase"
# 	}, "../app/etc/local.xml"
# )