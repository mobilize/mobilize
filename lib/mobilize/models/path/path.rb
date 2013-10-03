module Mobilize
  class Path
    include Mongoid::Document
    include Mongoid::Timestamps
    #a path is a location
    #that can read or write data.
    #
    def kind
      self.class.to_s.downcase.split("::").last
    end

    def cache(task)
      @path = self
      @task = task
      return "#{@task.job.cache}/#{self.kind}/#{@path.name}"
    end

    def cache_parent(task)
      @path = self
      return @path.cache(task).split("/")[0..-2].join("/")
    end

    def clear_cache(task)
      @path = self
      @task = task
      @path.purge_cache(@task)
      @path.create_cache(@task)
      Logger.info("Cleared cache for #{@task.id}")
    end

    def purge_cache(task)
      @path = self
      @task = task
      FileUtils.rm_r(@path.cache(@task),force: true)
      Logger.info("Purged cache for #{@task.id}")
    end

    def create_cache(task)
      @path = self
      @task = task
      FileUtils.mkdir_p(@path.cache(@task))
      #remove the actual directory so it can be written as file
      FileUtils.rm_r(@path.cache(@task),force: true)
      Logger.info("Created cache for #{@task.id}")
    end
  end
end
