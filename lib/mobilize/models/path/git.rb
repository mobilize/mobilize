module Mobilize
  class Git
    include Mongoid::Document
    include Mongoid::Timestamps
    #a git_path points to a specific repo
    field :domain, type: String, default:->{"github.com"}
    field :owner_name, type: String
    field :repo_name, type: String
    field :ssh_user_name, type: String, default:->{"git"}
    field :_id, type: String, default:->{"#{domain}:#{owner_name}/#{repo_name}"}

    validates :owner_name, :repo_name, presence: true

    def http_url
      g = self
      "https://#{g.domain}/#{g.owner_name}/#{g.repo_name}"
    end

    def git_http_url
      g = self
      "https://#{g.domain}/#{g.owner_name}/#{g.repo_name}.git"
    end

    def git_ssh_url
      g = self
      "#{g.ssh_user_name}@#{g.domain}:#{g.owner_name}/#{g.repo_name}.git"
    end

    def url
      g = self
      g.http_url
    end

    #clones repo into temp folder with depth of 1
    #checks out appropriate branch
    #needs user_id with git_ssh_key to get private repo
    def load(user_id=nil,run_dir=Dir.mktmpdir)
      g = self
      repo_dir = if user_id
                   g.priv_load(user_id,run_dir)
                 else
                   g.pub_load(run_dir)
                 end
      return repo_dir
    end

    def pub_load(run_dir)
      g = self
      cmd = "cd #{run_dir} && " +
            "git clone -q #{g.git_http_url.sub("https://","https://nobody:nobody@")} --depth=1"
      cmd.popen4(true)
      return "#{run_dir}/#{g.repo_name}"
    end

    def priv_load(user_id,run_dir)
      g = self
      key_value = User.find(user_id).git_key
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
            "git clone -q #{g.git_ssh_url} --depth=1"
      cmd.popen4(true)
      #remove aux files
      [key_file_path, git_file_path].each{|fp| FileUtils.rm(fp,force: true)}
      return "#{run_dir}/#{g.repo_name}"
    end
  end
end
