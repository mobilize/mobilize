module Mobilize
  class GitPath < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    #a git_path points to a file inside a specific branch of a git repo
    field :service, type: String, default:->{"git"}
    field :domain, type: String, default:->{"github.com"}
    field :owner_name, type: String
    field :repo_name, type: String
    field :branch, type: String, default:->{"master"}
    field :file_path, type: String #file within the branch
    field :address, type: String, default:->{"#{domain}/#{owner_name}/#{repo_name}/#{branch}/#{file_path}"}
    field :url, type: String, default:->{ "#{service}://#{address}" } #unique identifier
    field :http_url, type: String, default:->{"https://#{domain}/#{owner_name}/#{repo_name}/blob/#{branch}/#{file_path}"}
    field :http_url_repo, type: String, default:->{"https://#{domain}/#{owner_name}/#{repo_name}.git"}
    field :git_user_name, type: String, default:->{"git"}
    field :ssh_url_repo, type: String, default:->{"#{git_user_name}@#{domain}:#{owner_name}/#{repo_name}.git"}

    validates :owner_name, :repo_name, presence: true

    #clones repo into temp folder with depth of 1
    #checks out appropriate branch
    def load(user=Mobilize.owner,run_dir=Dir.mktmpdir)
      gp = self
      #try http access first
      #public repo; use http access with nobody:nobody credentials
      cmd = "cd #{run_dir} && " +
            "git clone -q #{gp.http_url_repo.sub("https://","https://nobody:nobody@")} --depth=1 && " +
            "cd #{gp.repo_name} && git checkout #{gp.branch}"
      begin
        cmd.popen4(true)
      rescue
        #public access failed;
        #requires appropriate user permissions
        #given by private key
        key_value = user.git_key
        #create key file, set permissions, write key
        key_file_path = run_dir + "/key.ssh"
        File.open(key_file_path,"w") {|f| f.print(key_value)}
        "chmod 0600 #{key_file_path}".popen4
        #set git to not check strict host
        git_ssh_cmd = "#!/bin/sh\nexec /usr/bin/ssh -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no'"
        git_ssh_cmd += " -i #{key_file_path} \"$@\""
        git_file_path = run_dir + "/git.ssh"
        File.open(git_file_path,"w") {|f| f.print(git_ssh_cmd)}
        "chmod 0700 #{git_file_path}".popen4
        #add keys, clone repo, go to specific revision, execute command
        cmd = "export GIT_SSH=#{git_file_path} && " +
              "cd #{run_dir} && " +
              "git clone -q #{gp.ssh_url_repo} --depth=1 && " +
              "cd #{gp.repo_name} && git checkout #{gp.branch}"
        cmd.popen4(true)
      end
      repo_dir = "#{run_dir}/#{gp.repo_name}"
      return repo_dir
    end

    #loads repo and returns file contents as string
    def read(user=Mobilize.owner)
      gp = self
      repo_dir = gp.load
      File.read("#{repo_dir}/#{file_path}")
    end
  end
end
