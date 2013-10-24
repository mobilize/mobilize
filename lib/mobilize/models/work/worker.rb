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
      _worker                 = self
      _pack_cmd               = "cd #{_worker.parent_dir} && " +
                                "tar -zcvf #{_worker.dir}.tar.gz " +
                                "#{File.basename(_worker.dir)}"
      _pack_cmd.popen4(true)
      Logger.write              "Packed worker for #{_task.id} in #{_worker.dir}.tar.gz"
    end
  end
end
