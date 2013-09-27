module Mobilize
  class Github < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    #a github points to a specific repo
    field :domain, type: String, default:->{"github.com"}
    field :owner_name, type: String
    field :repo_name, type: String
    field :name, type: String, default:->{repo_name}
    field :_id, type: String, default:->{"github://#{domain}/#{owner_name}/#{repo_name}"}

    validates :owner_name, :repo_name, presence: true

    @@config = Mobilize.config.github

    def http_url
      @github = self
      "https://#{@github.domain}/#{@github.owner_name}/#{@github.repo_name}"
    end

    def git_http_url
      @github = self
      "https://#{@github.domain}/#{@github.owner_name}/#{@github.repo_name}.git"
    end

    def git_ssh_url
      @github = self
      "git@#{@github.domain}:#{@github.owner_name}/#{@github.repo_name}.git"
    end

    def url
      @github = self
      @github.http_url
    end

    def Github.session
      @session = ::Github.new(login: @@config.owner_login, password: @@config.owner_password)
      Logger.info("Logged into Github.")
      return @session
    end

    def repo_call(task,action,category=nil)
      @github = self
      @task = task
      begin
        @connection = @task.session.repos
        @connection = category ? @connection.send(category) : @connection
        @response = @connection.send(action,user: @github.owner_name, repo: @github.repo_name)
        Logger.info("#{[action,category].compact.join(".")} successful for #{@github._id} repo call; " +
                    "#{@response.headers.ratelimit_remaining} calls left this hour")
      rescue
        Logger.error("Could not access #{@github._id}")
      end
      return @response
    end

    def is_private?(task)
      @github = self
      @task = task
      @response = @github.repo_call(@task,"get")
      if @response.body[:private]
        Logger.info("repo #{@github._id} is private")
        return true
      else
        Logger.info("repo #{@github._id} is public")
        return false
      end
    end

    def collaborators(task)
      @github = self
      @task = task
      @response = @github.repo_call(@task,"list","collaborators")
      return @response.body.map{|b| b[:login]}
    end

    #clones repo into temp folder with depth of 1
    #checks out appropriate branch
    #needs user_id with git_ssh_key to get private repo
    def read(task)
      @github = self
      @task = task
      @github.clear_cache(@task)
      if @github.is_private?(@task)
        @github.read_private(@task)
      else
        @github.read_public(@task)
      end
      #get size of objects and log
      log_cmd = "cd #{@github.cache(@task)} && git count-objects -H"
      size = log_cmd.popen4
      Logger.info("Read #{@github.id} into #{@github.cache(@task)}: #{size}")
      return true
    end

    def read_public(task)
      @github = self
      @task = task
      cmd = "cd #{@github.cache_parent(@task)} && " +
            "git clone -q #{@github.git_http_url.sub("https://","https://nobody:nobody@")} --depth=1"
      cmd.popen4(true)
      Logger.info("Read public git repo #{@github._id}")
      return true
    end

    def verify_collaborator(task)
      @github = self
      @task = task
      @user = task.user
      if @github.collaborators(@task).include?(@user.github_login)
        Logger.info("Verified user #{@user._id} has access to #{@github._id}")
        return true
      else
        Logger.error("User #{@user._id} does not have access to #{@github._id}")
      end
    end

    def read_private(task)
      @github = self
      @task = task
      #determine if the user in question is a collaborator on the repo
      @github.verify_collaborator(@task)
      #thus verified, get the ssh key and pull down the repo
      @github.add_git_file(@task)
      #add keys, clone repo, go to specific revision, execute command
      cmd = "export GIT_SSH=#{@github.git_ssh_file_path(@task)} && " +
            "cd #{@github.cache_parent(@task)} && " +
            "git clone -q #{@github.git_ssh_url} --depth=1"
      cmd.popen4(true)
      @github.remove_git_files(@task)
      Logger.info("Read private git repo #{@github._id}")
      return true
    end

    def git_ssh_file_path(task)
      "#{self.cache_parent(task)}/git.ssh"
    end

    def add_git_file(task)
      @github = self
      @task = task
      #set git to not check strict host
      git_ssh_cmd = "#!/bin/sh\nexec /usr/bin/ssh " +
                    "-o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' " +
                    "-i #{@@config.owner_ssh_key_path} \"$@\""
      File.open(@github.git_ssh_file_path(@task),"w") {|f| f.print(git_ssh_cmd)}
      "chmod 0700 #{@github.git_ssh_file_path(@task)}".popen4
      Logger.info("Added git files for repo #{@github._id}")
      return true
    end

    def remove_git_files(task)
      FileUtils.rm(self.git_ssh_file_path(task),force: true)
    end
  end
end
