require "mobilize/version"

module Mobilize
  #folder where project is installed
  def Mobilize.root
    File.expand_path "#{File.dirname(File.expand_path(__FILE__))}/.."
  end
  def Mobilize.env
    #use MOBILIZE_ENV to manually set your environment when you start your app
    ENV['MOBILIZE_ENV'] || "development"
  end
  def Mobilize.home_dir
    "~/.mobilize"
  end
  def Mobilize.log_dir
    "#{Mobilize.home_dir}/log"
  end
  def Mobilize.queue
    "mobilize-#{Mobilize.env}"
  end
end

#create log folder if not exists
@abs_log_dir                  = File.expand_path Mobilize.log_dir
FileUtils.mkdir_p               @abs_log_dir unless File.exists? @abs_log_dir
require "logger"
require "mobilize/logger"

#write sample config files if not available
require "#{Mobilize.root}/config/config"
@config_files = ["mob.yml"]
@config_files.each{|file_name| Mobilize::Config.write_from_sample file_name }

module Mobilize
  def Mobilize.config(model=nil)
    @@config ||= begin
                   Config.new
                 rescue
                   nil
                 end
    if @@config
      model ? @@config.send(model) : @@config
    end
  end
  #force Mobilize context when running `bundle console`
  def Mobilize.console
    Mobilize.pry
  end
  def Mobilize.db
    Mongoid.session(:default)[:database].database
  end
end
Mobilize.config

cli_dir = "mobilize/cli"
require "#{cli_dir}/cli"

require 'pry'

require 'mongoid'
@mongoid_config_path     = "#{Mobilize.root}/config/mongoid.yml"
begin
  @Mongodb               = Mobilize.config.mongodb

  @mongoid_config_hash   = { Mobilize.env => {
                             'sessions'   =>
                           { 'default'    =>
                           {
                             'username'             => @Mongodb.username,
                             'password'             => @Mongodb.password,
                             'database'             => @Mongodb.database,
                             'persist_in_safe_mode' => true,
                             'hosts'                => @Mongodb.hosts
                           }
                           }
                           }}

Mobilize::Config.write_from_hash    @mongoid_config_path, @mongoid_config_hash
Mongoid.load!             @mongoid_config_path, Mobilize.env
FileUtils.rm              @mongoid_config_path
rescue                   => exc
  puts "Unable to load Mongoid with current configs, skipping"
end

test_dir = "#{Mobilize.root}/test"
require "#{test_dir}/travis"

extensions_dir = "mobilize/extensions"
require "#{extensions_dir}/object"
require "#{extensions_dir}/string"
require "#{extensions_dir}/yaml"
require "#{extensions_dir}/net-ssh"

models_dir = "mobilize/models"

require "#{models_dir}/master"
require "#{models_dir}/user"

work_dir = "#{models_dir}/work"
require "#{work_dir}/work"
require "#{work_dir}/job"
require "#{work_dir}/trigger"
require "#{work_dir}/stage"
require "#{work_dir}/task"
require "#{work_dir}/task/cache"
require "#{work_dir}/task/worker"

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
