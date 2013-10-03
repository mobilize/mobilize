module Mobilize
  # a cache is an ssh location which holds data
  # relevant to a given task
  class Cache
    include Mongoid::Document
    include Mongoid::Timestamps
    field :task_id, type: String
    belongs_to :task

    def dir
      @cache = self
      @task  = @cache.task
      return "#{Mobilize.config.cache.dir}/#{@task.user.id}/#{@task.name}".gsub("~",self.home_dir)
    end

    def create
      @cache  = self
      @task = @cache.task
      @ssh = @task.user.ec2
      #clear out and regenerate server folder
      @ssh.sh("mkdir -p #{@cache.dir}")
      Logger.info("Created cache in #{@cache.dir}")
      return true
    end

    def purge
      @ssh  = self
      @task = task
      @ssh.sh("sudo rm -rf #{@ssh.cache(@task)}*")
      Logger.info("Purged cache for #{@task.id}")
    end
  end
end
