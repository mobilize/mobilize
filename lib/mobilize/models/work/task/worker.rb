module Mobilize
  # a worker links a task to a resque job
  # and a local directory that stores data before it is cached
  class Worker
    include Mongoid::Document
    include Mongoid::Timestamps
    field :task_id, type: String
    field :_id,     type: String, default:->{"#{task_id}.worker"}
    belongs_to :task

    def dir
      @worker                   = self
      @task                     = @worker.task
      @is_ssh                   = @task.path.class == Mobilize::Ssh
      if @is_ssh
        @stdin_path             = File.expand_path "#{@worker.job_dir}/ssh/stdin"
        return                    @stdin_path
      else
        @dir                    = File.expand_path @worker.abs_dir
        return                    @dir
      end
    end

    def job_dir
      @worker                   = self
      @task                     = @worker.task
      @job_dir                  = "#{Job.dir}/" +
                                  "#{@task.user.id}/#{@task.job.name}/#{@task.stage.name}"
      return                      @job_dir
    end

    def abs_dir
      @worker                   = self
      @abs_dir                  = "#{Mobilize.home_dir}/jobs/#{@worker.rel_dir}"
      return                      @abs_dir
    end

    def rel_dir
      @worker                   = self
      @task                     = @worker.task
      @rel_dir                  = @task.id.split("#").first
      return                      @rel_dir
    end

    def parent_dir
      @worker                   = self
      @parent_dir               = File.dirname @worker.dir
      return                      @parent_dir
    end

    def refresh
      @worker                   = self
      @worker.purge
      @worker.create
      Logger.info                 "Refreshed work dir #{@worker.dir}"
    end

    def purge
      @worker                  = self
      FileUtils.rm_r             @worker.dir, force: true
      Logger.info                "Purged work dir #{@worker.dir}"
    end

    def create
      @worker                  = self
      if File.exists?            @worker.dir
        Logger.info              "Work dir exists #{@worker.dir}"
      else
        Logger.info              "Created work dir #{@worker.dir}"
        FileUtils.mkdir_p        @worker.dir
      end
    end

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
