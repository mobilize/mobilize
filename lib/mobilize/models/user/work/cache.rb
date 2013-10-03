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

    def parent_dir
      @cache = self
      return File.dirname(@cache.dir)
    end

    def create
      @cache = self
      @task  = @cache.task
      @ssh   = @task.user.ec2.ssh
      #clear out and regenerate cache dir
      @ssh.sh("mkdir -p #{@cache.dir}")
      Logger.info("Created cache dir #{@cache.dir}")
      return true
    end

    def purge
      @cache = self
      @task  = @cache.task
      @ssh   = @task.user.ec2.ssh
      #also purge any tarballs
      @ssh.sh("sudo rm -rf #{@cache.dir}*")
      Logger.info("Purged cache dir #{@cache.dir}")
    end

    def refresh
      @cache = self
      @cache.purge
      @cache.create
      Logger.info("Refreshed cache dir #{@cache.dir}")
    end

    def unpack
      @cache = self
      @task = task
      @ssh = @task.user.ec2.ssh
      cache_file = "#{File.basename(@cache.dir)}.tar.gz"
      @ssh.sh("cd #{@cache.parent_dir} && rm -rf #{@cache.dir} && tar -zxvf #{cache_file} && rm #{cache_file}")
      Logger.info("Unpacked cache for #{@task.id}")
    end
  end
end
