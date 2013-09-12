module Mobilize
  class Github
    include Mongoid::Document
    include Mongoid::Timestamps
    #a github points to a specific repo
    field :domain, type: String, default:->{"github.com"}
    field :owner_name, type: String
    field :repo_name, type: String
    field :_id, type: String, default:->{"#{domain}:#{owner_name}/#{repo_name}"}

    validates :owner_name, :repo_name, presence: true

    def http_url
      gh = self
      "https://#{gh.domain}/#{gh.owner_name}/#{gh.repo_name}"
    end

    def git_http_url
      gh = self
      "https://#{gh.domain}/#{gh.owner_name}/#{gh.repo_name}.git"
    end

    def git_ssh_url
      gh = self
      "git@#{gh.domain}:#{gh.owner_name}/#{gh.repo_name}.git"
    end

    def url
      gh = self
      gh.http_url
    end

    def Github.login
      session = Github.new(login: ENV['MOB_OWNER_GITHUB_LOGIN'], password: ENV['MOB_OWNER_GITHUB_PASSWORD'])
      Logger.info("Logged into Github.")
      return session
    end

    def is_private?
      gh = self
      session ||= Github.login
      resp = begin
               resp = session.repos.get(user: gh.owner_name, repo: gh.repo_name)
               Logger.info("Got repo for #{gh._id}")
             rescue
               Logger.error("Could not access #{gh._id}")
             end
      return resp.body[:private]
    end

    #clones repo into temp folder with depth of 1
    #checks out appropriate branch
    #needs user_id with git_ssh_key to get private repo
    def load(user_id=nil,run_dir=Dir.mktmpdir)
      gh = self
      session ||= Github.login
      repo_dir = if gh.is_private?
                   gh.priv_load(user_id,run_dir)
                 else
                   gh.pub_load(run_dir)
                 end
      return repo_dir
    end

    def pub_load(run_dir)
      gh = self
      cmd = "cd #{run_dir} && " +
            "git clone -q #{gh.git_http_url.sub("https://","https://nobody:nobody@")} --depth=1"
      cmd.popen4(true)
      Logger.info("Loaded public git repo #{gh._id}")
      return "#{run_dir}/#{gh.repo_name}"
    end

    def collaborators(session=nil)
      gh = self
      session ||= Github.login
      resp = begin
               session.repos.collaborators.list(user: gh.owner_name, repo: gh.repo_name)
               Logger.info("Got collaborators for #{gh._id}")
             rescue
               Logger.error("Could not access #{gh._id}")
             end
      return resp.body.map{|b| b[:login]}
    end

    def verify_collaborator(user_id, session=nil)
      gh = self
      session ||= Github.login
      u = User.find(user_id)
      if gh.collaborators.include?(u.github_login)
        Logger.info("Verified user #{u._id} has access to #{gh._id}")
        return true
      else
        Logger.error("User #{u._id} does not have access to #{gh._id}")
      end
    end

    def priv_load(user_id,run_dir)
      gh = self
      #determine if the user in question is a collaborator on the repo
      gh.verify_collaborator(user_id)
      #thus verified, get the ssh key and pull down the repo
      key_value = File.read(ENV['MOB_OWNER_GITHUB_SSH_KEY_PATH'])
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
            "git clone -q #{gh.git_ssh_url} --depth=1"
      cmd.popen4(true)
      #remove aux files
      [key_file_path, git_file_path].each{|fp| FileUtils.rm(fp,force: true)}
      Logger.info("Loaded private git repo #{gh._id}")
      return "#{run_dir}/#{gh.repo_name}"
    end
  end
end
