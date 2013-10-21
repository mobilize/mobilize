require "mobilize/version"

module Mobilize
  #folder where project is installed
  def Mobilize.root
    File.expand_path "#{File.dirname(File.expand_path(__FILE__))}/.."
  end
  def Mobilize.env
    ENV['MOBILIZE_ENV'] || "development"
  end
  def Mobilize.home_dir
    File.expand_path "~/.mobilize"
  end
  def Mobilize.log_dir
    "#{Mobilize.home_dir}/log"
  end
  def Mobilize.queue
    "mobilize-#{Mobilize.env}"
  end
end

#create log folder if not exists
_abs_log_dir                  = File.expand_path Mobilize.log_dir
FileUtils.mkdir_p               _abs_log_dir unless File.exists? _abs_log_dir
require "logger"
require "mobilize/logger"

#write sample config files if not available
require "mobilize/config"
Mobilize::Config.load_rc
Mobilize::Config.write_from_sample "config.yml"

module Mobilize
  def Mobilize.config(model = nil)
    _model     = model
    @@config ||= Mobilize::Config.new
    if @@config
      _model ? @@config.send(_model) : @@config
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

require "cli"

require 'pry'

require 'mongoid'
_mongoid_config_path     = "#{Mobilize::Config.dir}/mongoid.yml"
begin
  _Mongodb               = Mobilize.config.mongodb

  _mongoid_config_hash   = { Mobilize.env => {
                             'sessions'   =>
                           { 'default'    =>
                           {
                             'username'             => _Mongodb.username,
                             'password'             => _Mongodb.password,
                             'database'             => _Mongodb.database,
                             'persist_in_safe_mode' => true,
                             'hosts'                => _Mongodb.hosts.split(",")
                           }
                           }
                           }}

Mobilize::Config.write_from_hash    _mongoid_config_path, _mongoid_config_hash
Mongoid.load!                       _mongoid_config_path, Mobilize.env
FileUtils.rm                        _mongoid_config_path
rescue                           => exc
  Mobilize::Logger.write            "Unable to load Mongoid with current configs: #{exc.to_s}"
end

test_dir = "#{Mobilize.root}/test"
require "#{test_dir}/travis"

extensions_dir = "mobilize/extensions"
require "#{extensions_dir}/object"
require "#{extensions_dir}/string"
require "#{extensions_dir}/yaml"

models_dir = "mobilize/models"

require "#{models_dir}/master"
require "#{models_dir}/user"

work_dir = "#{models_dir}/work"
require "#{work_dir}/work"
require "#{work_dir}/job"
require "#{work_dir}/trigger"
require "#{work_dir}/stage"
require "#{work_dir}/task"
require "#{work_dir}/worker"

path_dir = "#{models_dir}/path"
require "#{path_dir}/path"
require 'github_api'
require "#{path_dir}/github"
require "resque"

require "popen4"
require "#{path_dir}/script"

require      "aws"
require      "net/ssh"
require      "net/scp"
box_dir    = "#{models_dir}/box"
action_dir = "#{box_dir}/action"
require      "#{action_dir}/install"
require      "#{action_dir}/write"
require      "#{action_dir}/action"
require      "#{box_dir}/box"
require      "#{box_dir}/extensions/net-ssh.rb"

unless File.exists? Mobilize::Github.sh_path and
       File.exists? Mobilize::Box.private_key_path

       Mobilize::Config.write_key_files
end

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
