module Mobilize
  # a worker links a task to a resque job
  # and a local directory that stores data before it is cached
  class Worker
    include Mongoid::Document
    include Mongoid::Timestamps
    field :task_id, type: String
    field :_id, type: String, default:->{"#{task_id}.worker"}
    belongs_to :task

    def dir
      @worker = self
      return File.expand_path(@worker.abs_dir)
    end

    def abs_dir
      @worker = self
      return "#{Mobilize::Config.home_dir}/jobs/#{@worker.rel_dir}"
    end

    def rel_dir
      @worker = self
      @task = @worker.task
      return "#{@task.job.name}/#{@task.name}/#{@path.id}"
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
