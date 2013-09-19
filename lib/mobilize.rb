require "mobilize/version"

require "mobilize/logger"
mob_yml_path = File.expand_path("~/.mob.yml")
unless File.exists?(mob_yml_path)
  Mobilize:: Logger.error("no ~/.mob.yml file found; " +
                          "please run `mob configure` to set up a default file, " +
                          "and be sure to populate environment variables appropriate to your setup")
end

require "settingslogic"
require "mobilize/config"

module Mobilize
  @@config = Config.new

  #folder where project is installed
  def Mobilize.root
    ENV['PWD']
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

require 'pry'
require "popen4"
require 'net/ssh'
require 'net/scp'

require 'mongoid'
mongoid_config_path = "#{Mobilize.root}/config/mongoid.yml"
Mongoid.load!(mongoid_config_path, Mobilize.env)

deploy_dir = "#{Mobilize.root}/config/deploy"
require "#{deploy_dir}/travis"

extensions_dir = "mobilize/extensions"
require "#{extensions_dir}/object"
require "#{extensions_dir}/string"
require "#{extensions_dir}/yaml"
require "#{extensions_dir}/net-ssh"
require "#{extensions_dir}/class"

models_dir = "mobilize/models"
user_dir = "#{models_dir}/user"
require "#{user_dir}/user"
require "#{user_dir}/schedule"
require "#{user_dir}/job"

path_dir = "#{models_dir}/path"
require "#{path_dir}/path"
require 'github_api'
require "#{path_dir}/github"

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

require 'optparse'
cli_dir = "mobilize/cli"
require "#{cli_dir}/cli"
