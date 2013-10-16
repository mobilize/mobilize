module Mobilize
  # a worker links a task to a resque job
  # and a local directory that stores data for run and write tasks
  class Worker
    include Mongoid::Document
    include Mongoid::Timestamps
    field :task_id, type: String
    field :_id,     type: String, default:->{"#{task_id}.worker"}
    belongs_to :task

    def pack
      @worker                 = self
      @task                   = task
      @pack_cmd               = "cd #{@worker.parent_dir} && " +
                                "tar -zcvf #{@worker.dir}.tar.gz " +
                                "#{File.basename(@worker.dir)}"
      @pack_cmd.popen4(true)
      Logger.info               "Packed worker for #{@task.id} in #{@worker.dir}.tar.gz"
    end
  end
end
