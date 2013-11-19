require "mobilize/version"

#write sample config files if not available
require "mobilize/config"
Mobilize::Config.load_rc

Mobilize::Config.write_from_sample "config.yml"

Mobilize::Config.write_from_sample "resque-pool-test.rb"

module Mobilize
  def Mobilize.config( _model = nil )
    @@config ||= Mobilize::Config.new
    if @@config
      _model ? @@config.send( _model ) : @@config
    end
  end
end
Mobilize.config

Mobilize::Config.connect_mongodb

_extensions_dir = "mobilize/extensions"
require           "#{ _extensions_dir }/object"
require           "#{ _extensions_dir }/string"
require           "#{ _extensions_dir }/array"
require           "#{ _extensions_dir }/yaml"
require           "#{ _extensions_dir }/time"

require           'colorize'
require           'mobilize/log'
require           "mobilize/cli"
require           "mobilize/attempter"

_models_dir     = "mobilize/models"

require           "#{ _models_dir }/user"
require           "#{ _models_dir }/crontab"

_work_dir       = "#{ _models_dir }/work"
require           "#{ _work_dir }/work"
_cron_dir       = "#{ _work_dir }/cron"
require           "#{ _cron_dir }/trigger"
require           "#{ _cron_dir }/cron"
require           "#{ _work_dir }/job"
require           "#{ _work_dir }/stage"
require           "#{ _work_dir }/task"

_path_dir       = "#{ _models_dir }/path"
require           "#{ _path_dir }/path"
require           'github_api'
require           "#{ _path_dir }/github"
require           "resque"

require           "popen4"
require           "#{ _path_dir }/script"

require           "aws"
require           "net/ssh"
require           "net/scp"
_cluster_dir    = "#{ _models_dir }/cluster"
_box_dir        = "#{ _cluster_dir }/box"
require           "#{ _box_dir }/action"
require           "#{ _box_dir }/box"
require           "#{ _box_dir }/extensions/net-ssh.rb"

require           "#{ _cluster_dir }/cluster"
require           "#{ _cluster_dir }/engine"
require           "#{ _cluster_dir }/master"

if Mobilize::Box.find_self
  Resque.redis = Redis.new host:     Mobilize.config.redis.host,
                           port:     Mobilize.config.redis.port,
                           password: Mobilize.config.redis.password

end

_google_dir     = "#{ _path_dir }/google"

require           "google_drive"
require           "#{ _google_dir }/gfile"
#patched from google-drive-ruby
require           "#{ _google_dir }/extensions/client_login_fetcher"
