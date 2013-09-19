module Mobilize
  class Github < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    #a github points to a specific repo
    field :domain, type: String, default:->{"github.com"}
    field :owner_name, type: String
    field :repo_name, type: String
    field :_id, type: String, default:->{"#{domain}:#{owner_name}/#{repo_name}"}

    validates :owner_name, :repo_name, presence: true

    @@config = Mobilize.config

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

    def Github.login
      @session = ::Github.new(login: @@config.github.owner_login, password: @@config.github.owner_password)
      Logger.info("Logged into Github.")
      return @session
    end

    def is_private?(session=nil)
      @github = self
      @session = session || Github.login
      begin
        resp = @session.repos.get(user: @github.owner_name, repo: @github.repo_name)
        Logger.info("Got repo for #{@github._id}; #{resp.headers.ratelimit_remaining} calls left this hour")
      rescue
        Logger.error("Could not access #{@github._id}")
      end
      if resp.body[:private]
        Logger.info("repo #{@github._id} is private")
        return true
      else
        Logger.info("repo #{@github._id} is public")
        return false
      end
    end

    #performs a github load in preparation for a Transfer
    def Github.perform(github_id,transfer_id)
      @github = Github.find(github_id)
      @transfer = Transfer.find(transfer_id)
      @github.load(@transfer.user_id,@transfer.local)
      return true
    end

    #clones repo into temp folder with depth of 1
    #checks out appropriate branch
    #needs user_id with git_ssh_key to get private repo
    def load(user_id=nil,run_dir=Dir.mktmpdir)
      @github = self
      @session ||= Github.login
      repo_dir = if @github.is_private?(@session)
                   @github.priv_load(user_id,run_dir)
                 else
                   @github.pub_load(run_dir)
                 end
      Logger.info("Loaded #{@github.id} into #{run_dir}")
      return repo_dir
    end

    def pub_load(run_dir)
      @github = self
      cmd = "cd #{run_dir} && " +
            "git clone -q #{@github.git_http_url.sub("https://","https://nobody:nobody@")} --depth=1"
      cmd.popen4(true)
      Logger.info("Loaded public git repo #{@github._id}")
      return "#{run_dir}/#{@github.repo_name}"
    end

    def collaborators(session=nil)
      @github = self
      @session ||= Github.login
      begin
        resp = @session.repos.collaborators.list(user: @github.owner_name, repo: @github.repo_name)
        Logger.info("Got collaborators for #{@github._id}; #{resp.headers.ratelimit_remaining} calls left this hour")
      rescue
        Logger.error("Could not access #{@github._id}")
      end
      return resp.body.map{|b| b[:login]}
    end

    def verify_collaborator(user_id, session=nil)
      @github = self
      @session = session || Github.login
      u = User.find(user_id)
      if @github.collaborators.include?(u.github_login)
        Logger.info("Verified user #{u._id} has access to #{@github._id}")
        return true
      else
        Logger.error("User #{u._id} does not have access to #{@github._id}")
      end
    end

    def priv_load(user_id,run_dir)
      @github = self
      #determine if the user in question is a collaborator on the repo
      @github.verify_collaborator(user_id)
      #thus verified, get the ssh key and pull down the repo
      key_value = File.read(@@config.github.owner_ssh_key_path)
      #create key file, set permissions, write key
      key_file_path = run_dir + "/key.ssh"
      File.open(key_file_path,"w") {|f| f.print(key_value)}
      "chmod 0600 #{key_file_path}".popen4
      #set git to not check strict host
      git_ssh_cmd = "#!/bin/sh\nexec /usr/bin/ssh -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' -i #{key_file_path} \"$@\""
      git_file_path = run_dir + "/git.ssh"
      File.open(git_file_path,"w") {|f| f.print(git_ssh_cmd)}
      "chmod 0700 #{git_file_path}".popen4
      #add keys, clone repo, go to specific revision, execute command
      cmd = "export GIT_SSH=#{git_file_path} && " +
            "cd #{run_dir} && " +
            "git clone -q #{@github.git_ssh_url} --depth=1"
      cmd.popen4(true)
      #remove aux files
      [key_file_path, git_file_path].each{|fp| FileUtils.rm(fp,force: true)}
      Logger.info("Loaded private git repo #{@github._id}")
      return "#{run_dir}/#{@github.repo_name}"
    end
  end
end
