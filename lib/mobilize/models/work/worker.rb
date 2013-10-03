module Mobilize
  # a is a resque location that holds data
  # relevant to a given task
  class Worker
    include Mongoid::Document
    include Mongoid::Timestamps
    field :task_id, type: String
    belongs_to :task

    def dir
      @worker = self
      @task = @worker.task
      return "#{@task.job.name}/#{@task.name}/#{@task.path.kind}/#{@path.name}"
    end

    def parent_dir
      @cache = self
      return File.dirname(@cache.dir)
    end

    def clear
      @cache = self
      @cache.purge
      @cache.create
      Logger.info("Cleared cache for #{@cache.dir}")
    end

    def purge
      @cache = self
      FileUtils.rm_r(@cache.dir,force: true)
      Logger.info("Purged cache for #{@cache.dir}")
    end

    def create
      @cache = self
      FileUtils.mkdir_p(@cache.dir)
      Logger.info("Created cache for #{@cache.dir}")
    end
  end
end
