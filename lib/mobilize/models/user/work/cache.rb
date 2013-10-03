module Mobilize
  # a cache is an ssh location which holds data
  # relevant to a given task
  class Cache
    include Mongoid::Document
    include Mongoid::Timestamps
    field :task_id, type: String
    field :_id, type: String, default:->{"#{task_id}.cache"}
    belongs_to :task

    #same as worker dir but with ssh home dir
    def dir
      @cache = self
      @task  = @cache.task
      @ssh = @task.user.ec2.ssh
      return @task.worker.abs_dir.sub("~",@ssh.home_dir)
    end

    def create
      @cache = self
      @task  = @cache.task
      @ssh   = @task.user.ec2.ssh
      #clear out and regenerate server folder
      @ssh.sh("mkdir -p #{@cache.dir}")
      Logger.info("Created cache dir #{@cache.dir}")
      return true
    end

    def purge
      @cache = self
      @task  = @cache.task
      @ssh   = @task.user.ec2.ssh
      @ssh.sh("sudo rm -rf #{@cache.dir}")
      Logger.info("Purged cache dir #{@cache.dir}")
    end

    def refresh
      @cache = self
      @cache.purge
      @cache.create
      Logger.info("Refreshed cache dir #{@cache.dir}")
    end
  end
end
