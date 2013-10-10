module Mobilize
  # a cache is an ssh location which holds data
  # relevant to a given task
  class Cache
    include Mongoid::Document
    include Mongoid::Timestamps
    field :task_id, type: String
    field :_id,     type: String, default:->{"#{task_id}.cache"}
    belongs_to :task

    #same as worker dir but with ssh home dir
    #except for the ssh path cache
    #which is <job_dir>/ssh/in
    def dir
      @cache            = self
      @task             = @cache.task
      @is_ssh           = @task.path.class == Mobilize::Ssh
      if @is_ssh
        return            "#{@cache.job_dir}/ssh/stdin"
      else
        @ssh            = @task.user.ec2.ssh
        @dir            = @task.worker.abs_dir.sub("~",@ssh.home_dir)
        return            @dir
      end
    end

    def parent_dir
      @cache            = self
      return              File.dirname @cache.dir
    end

    def home_dir
      @cache            = self
      @task             = @cache.task
      @ssh              = @task.user.ec2.ssh
      @home_dir         = Mobilize::Config.home_dir.sub("~",@ssh.home_dir)
      return              @home_dir
    end

    def job_dir
      @cache            = self
      @task             = @cache.task
      @job_dir          = "#{@cache.home_dir}/jobs/#{@task.user.id}/#{@task.job.name}"
      return              @job_dir
    end

    def create
      @cache            = self
      @task             = @cache.task
      @ssh              = @task.user.ec2.ssh
      #clear out and regenerate cache dir
      @ssh.sh           "mkdir -p #{@cache.dir}"
      Logger.info       "Created cache dir #{@cache.dir}"
      return            true
    end

    def purge
      @cache            = self
      @task             = @cache.task
      @ssh              = @task.user.ec2.ssh
      #also purge any tarballs
      @ssh.sh             "sudo rm -rf #{@cache.dir}*"
      Logger.info         "Purged cache dir #{@cache.dir}"
    end

    def refresh
      @cache            = self
      @cache.purge
      @cache.create
      Logger.info         "Refreshed cache dir #{@cache.dir}"
    end

    def unpack
      @cache            = self
      @task             = task
      @ssh              = @task.user.ec2.ssh
      @cache_file       = "#{File.basename(@cache.dir)}.tar.gz"
      @ssh.sh             "cd #{@cache.parent_dir} && " +
                          "rm -rf #{@cache.dir} && " +
                          "tar -zxvf #{@cache_file} && rm #{@cache_file}"
      Logger.info         "Unpacked cache into #{@cache.dir}"
    end
  end
end
