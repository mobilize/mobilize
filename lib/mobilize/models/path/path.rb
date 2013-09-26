module Mobilize
  class Path
    include Mongoid::Document
    include Mongoid::Timestamps
    #a path is a location
    #that can read or write data.
  end

  def kind
    self.class.to_s.downcase.split("::").last
  end

  def clear_cache(task)
    @path = self
    @task = task
    @path.purge_cache(@task)
    @path.create_cache(@task)
    Logger.info("Cleared cache for #{@task.id}")
  end

end
