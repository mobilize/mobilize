module Mobilize
  class Github < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    #a github points to a specific repo
    field :domain,              type: String, default:->{"github.com"}
    field :owner_name,          type: String
    field :repo_name,           type: String
    field :name,                type: String, default:->{"#{domain}/#{owner_name}/#{repo_name}"}
    field :_id,                 type: String, default:->{"github/#{name}"}

    @@config                  = Mobilize.config("github")

    def Github.sh_path;         Config.key_dir + "/git.sh"; end

    def Github.session
      @session                = ::Github.new login:    @@config.owner_login,
                                             password: @@config.owner_password
      Logger.write              "Logged into Github."
      return                    @session
    end

    def repo_call(task, action, category=nil)
      @github                 = self
      @task                   = task
      begin
        @connection           = @task.session.repos
        @connection           = category ? @connection.send(category) : @connection
        @response             = @connection.send action,
                                                 user: @github.owner_name,
                                                 repo: @github.repo_name
        @call                 = [action,category].compact.join(".")
        @calls_left           = @response.headers.ratelimit_remaining
        Logger.write            "#{@call} successful for #{@github._id} repo call; " +
                                "#{@calls_left} calls left this hour"
      rescue
        Logger.write            "Could not access #{@github._id}", "FATAL"
      end
      return                    @response
    end

    def collaborators(task)
      @github                 = self
      @task                   = task
      @response               = @github.repo_call @task,"list","collaborators"
      @collaborators          = @response.body.map{|b| b[:login]}
      return                    @collaborators
    end

    #clones repo into worker with depth of 1
    #checks out appropriate branch
    #needs user_id with git_ssh_key to get private repo
    def read(task)
      @github                = self
      @task                  = task
      @task.purge_dir
      begin
        Logger.write           "attempting public read for #{@github.id}"
        @github.read_public    @task
      rescue
        Logger.write           "public read failed, attempting private read for #{@github.id}"
        @github.read_private   @task
      end
      #get size of objects and log, formatted for no line breaks
      @log_cmd               = "cd #{@task.dir} && git count-objects -v"

      @size                  = @log_cmd.popen4.split("\n").join(", ")

      Logger.write             "Read #{@github.id} into #{@task.dir}"

      @stat                  = @task.user.google_login + ": " + @size
      Logger.write             @stat, "STAT"
      #deploy github repo
      return                   true
    end

    def read_public(task)
      @github                = self
      @task                  = task
      @cmd                   = "cd #{@task.path_dir} && " +
                               "git clone -q https://u:p@#{@github.name}.git --depth=1"
      @cmd.popen4(true)
      Logger.write             "Read complete: #{@github._id}"
      return true
    end

    def verify_collaborator(task)
      @github                = self
      @task                  = task
      @user                  = task.user
      @is_collaborator       = @github.collaborators(@task).include?(@user.github_login)

      if @is_collaborator
        Logger.write           "Verified user #{@user._id} has access to #{@github._id}"
        return                 true
      else
        Logger.write           "User #{@user._id} does not have access to #{@github._id}", "FATAL"
      end
    end

    def read_private(task)
      @github                     = self
      @task                       = task
      #determine if the user in question is a collaborator on the repo
      @github.verify_collaborator   @task
      #add key, clone repo, go to specific revision, execute command
      @cmd                        = "export GIT_SSH=#{Github.sh_path} && " +
                                    "cd #{@task.path_dir} && " +
                                    "git clone -q git@#{@github.name.sub("/",":")}.git --depth=1"
      @cmd.popen4(true)
      Logger.write                  "Read private git repo #{@github._id}"
      return                        true
    end
  end
end
