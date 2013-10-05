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
      if @task.path.class      == Mobilize::Ssh
        return File.expand_path "#{@worker.job_dir}/ssh/stdin"
      else
        return File.expand_path @worker.abs_dir
      end
    end

    def job_dir
      @worker = self
      @task   = @worker.task
      return "#{Mobilize::Config.home_dir}/jobs/#{@task.user.id}/#{@task.job.name}"
    end

    def abs_dir
      @worker = self
      return  "#{Mobilize::Config.home_dir}/jobs/#{@worker.rel_dir}"
    end

    def rel_dir
      @worker = self
      @task   = @worker.task
      return  @task.id.split("#").first
    end

    def parent_dir
      @worker = self
      return  File.dirname(@worker.dir)
    end

    def refresh
      @worker     = self
      @worker     .purge
      @worker     .create
      Logger.info "Refreshed work dir #{@worker.dir}"
    end

    def purge
      @worker        = self
      FileUtils.rm_r @worker.dir,force: true
      Logger.info    "Purged work dir #{@worker.dir}"
    end

    def create
      @worker           = self
      if File.exists?(@worker.dir)
        Logger.info "Work dir exists #{@worker.dir}"
      else
        Logger.info "Created work dir #{@worker.dir}"
        FileUtils.mkdir_p @worker.dir
      end
    end

    def pack
      @worker     = self
      @task       = task
      pack_cmd    = "cd #{@worker.parent_dir} && " +
                    "tar -zcvf #{@worker.dir}.tar.gz " +
                    "#{File.basename(@worker.dir)}"
      pack_cmd    .popen4(true)
      Logger.info "Packed worker for #{@task.id} in #{@worker.dir}.tar.gz"
    end
  end
end
