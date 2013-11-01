require "mobilize/version"

#write sample config files if not available
require "mobilize/config"
Mobilize::Config.load_rc
Mobilize::Config.write_from_sample "config.yml"

Mobilize::Config.write_from_sample "resque-pool-test.rb"

#create log folder if not exists
_abs_log_dir                  = File.expand_path Mobilize.log_dir
FileUtils.mkdir_p               _abs_log_dir unless File.exists? _abs_log_dir

module Mobilize
  def Mobilize.config(_model = nil)
    @@config ||= Mobilize::Config.new
    if @@config
      _model ? @@config.send(_model) : @@config
    end
  end
end
Mobilize.config

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
                             'database'             => _Mongodb.database || "mobilize-#{Mobilize.env}",
                             'persist_in_safe_mode' => true,
                             'hosts'                => _Mongodb.hosts.split(",")
                           }
                           }
                           }}

Mobilize::Config.write_from_hash    _mongoid_config_path, _mongoid_config_hash
Mongoid.load!                       _mongoid_config_path, Mobilize.env
FileUtils.rm                        _mongoid_config_path
rescue                           => _exc
  puts                      "Unable to load Mongoid with current configs: #{_exc.to_s}"
end
require 'mobilize/log'
require "mobilize/cli"

_extensions_dir = "mobilize/extensions"
require "#{_extensions_dir}/object"
require "#{_extensions_dir}/string"
require "#{_extensions_dir}/yaml"
require "#{_extensions_dir}/array"

_models_dir = "mobilize/models"

require "#{_models_dir}/user"

_work_dir = "#{_models_dir}/work"
require "#{_work_dir}/work"
require "#{_work_dir}/job"
require "#{_work_dir}/trigger"
require "#{_work_dir}/stage"
require "#{_work_dir}/task"

_path_dir = "#{_models_dir}/path"
require "#{_path_dir}/path"
require 'github_api'
require "#{_path_dir}/github"
require "resque"

require "popen4"
require "#{_path_dir}/script"

require        "aws"
require        "net/ssh"
require        "net/scp"
_cluster_dir = "#{_models_dir}/cluster"
_box_dir     = "#{_cluster_dir}/box"
require        "#{_box_dir}/action"
require        "#{_box_dir}/box"
require        "#{_box_dir}/extensions/net-ssh.rb"

require        "#{_cluster_dir}/cluster"
require        "#{_cluster_dir}/engine"
require        "#{_cluster_dir}/master"

unless File.exists? Mobilize::Github.sh_path and
       File.exists? Mobilize::Box.private_key_path

       Mobilize::Config.write_key_files
end

_google_dir = "#{_path_dir}/google"

require "google_drive"
require "#{_google_dir}/gfile"
#patched from google-drive-ruby
require "#{_google_dir}/extensions/client_login_fetcher"
