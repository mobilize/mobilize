require "mobilize/version"

module Mobilize
  #folder where project is installed
  def Mobilize.root
    ENV['PWD']
  end
end

require "mobilize/logger"

require "config/config"
#write sample config files if not available
["mob.yml","mongoid.yml","resque-pool.yml"].each do |file_name|
  Mobilize::Config.write_sample(file_name)
end
module Mobilize
  def Mobilize.config(model=nil)
    @@config ||= begin
                   Config.new
                 rescue
                   nil
                 end
    if @@config
      model ? @@config.send(model) : @@config
    else
      Logger.info("Please configure #{model || "mobilize"} using `mob configure`")
    end
  end
  #force Mobilize context when running `bundle console`
  def Mobilize.console
    Mobilize.pry
  end
  def Mobilize.db
    Mongoid.session(:default)[:database].database
  end
  def Mobilize.env
    #use MOBILIZE_ENV to manually set your environment when you start your app
    ENV['MOBILIZE_ENV'] || "development"
  end
end
Mobilize.config

cli_dir = "mobilize/cli"
require "#{cli_dir}/cli"

require 'pry'

require 'mongoid'
mongoid_config_path = "#{Mobilize.root}/config/mongoid.yml"
if File.exists?(mongoid_config_path)
  Mongoid.load!(mongoid_config_path, Mobilize.env)
end

test_dir = "#{Mobilize.root}/test"
require "#{test_dir}/travis"

extensions_dir = "mobilize/extensions"
require "#{extensions_dir}/object"
require "#{extensions_dir}/string"
require "#{extensions_dir}/yaml"
require "#{extensions_dir}/net-ssh"
require "#{extensions_dir}/class"

models_dir = "mobilize/models"
user_dir = "#{models_dir}/user"
require "#{user_dir}/user"
require "#{user_dir}/job"
require "#{user_dir}/task"

path_dir = "#{models_dir}/path"
require "#{path_dir}/path"
require 'github_api'
require "#{path_dir}/github"
require "resque"

require "popen4"
require "net/ssh"
require "net/scp"
require "#{path_dir}/ssh"

require "aws"
amazon_dir = "#{path_dir}/amazon"
require "#{amazon_dir}/ec2"
require "#{amazon_dir}/hive"
require "#{amazon_dir}/rds"
require "#{amazon_dir}/s3"

require "gmail"
google_dir = "#{path_dir}/google"
gbook_dir = "#{google_dir}/gbook"
require "#{google_dir}/gmail"

require "google_drive"
require "#{google_dir}/gfile"
require "#{gbook_dir}/gbook"
require "#{gbook_dir}/gtab"
require "#{gbook_dir}/grange"
#patched from google-drive-ruby
require "#{google_dir}/extensions/client_login_fetcher"
