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
      _session                = ::Github.new login:    @@config.owner_login,
                                             password: @@config.owner_password
      Logger.write              "Logged into Github."
      _session
    end

    def repo_call(task, action, category=nil)
      _github                 = self
      _task                   = task
      begin
        _connection           = _task.session.repos
        _connection           = category ? _connection.send(category) : _connection
        _response             = _connection.send action,
                                                 user: _github.owner_name,
                                                 repo: _github.repo_name
        _call                 = [action,category].compact.join(".")
        _calls_left           = _response.headers.ratelimit_remaining
        Logger.write            "#{_call} successful for #{_github._id} repo call; " +
                                "#{_calls_left} calls left this hour"
      rescue
        Logger.write            "Could not access #{_github._id}", "FATAL"
      end
      _response
    end

    def collaborators(task)
      _github                 = self
      _task                   = task
      _response               = _github.repo_call _task,"list","collaborators"
      _collaborators          = _response.body.map{|b| b[:login]}
      _collaborators
    end

    #clones repo into worker with depth of 1
    #checks out appropriate branch
    #needs user_id with git_ssh_key to get private repo
    def read(task)
      _github                = self
      _task                  = task
      _task.purge_dir
      begin
        Logger.write           "attempting public read for #{_github.id}"
        _github.read_public    _task
      rescue
        Logger.write           "public read failed, attempting private read for #{_github.id}"
        _github.read_private   _task
      end
      #get size of objects and log, formatted for no line breaks
      _log_cmd               = "cd #{_task.dir} && git count-objects -v"

      _size                  = _log_cmd.popen4.split("\n").join(", ")

      Logger.write             "Read #{_github.id} into #{_task.dir}"

      _stat                  = _task.user.google_login + ": " + _size
      Logger.write             _stat, "STAT"
      #deploy github repo
      true
    end

    def read_public(task)
      _github                = self
      _task                  = task
      _cmd                   = "cd #{_task.path_dir} && " +
                               "git clone -q https://u:p@#{_github.name}.git --depth=1"
      _cmd.popen4(true)
      Logger.write             "Read complete: #{_github._id}"
      true
    end

    def verify_collaborator(task)
      _github                = self
      _task                  = task
      _user                  = task.user
      _is_collaborator       = _github.collaborators(_task).include?(_user.github_login)

      if _is_collaborator
        Logger.write           "Verified user #{_user._id} has access to #{_github._id}"
        true
      else
        Logger.write           "User #{_user._id} does not have access to #{_github._id}", "FATAL"
      end
    end

    def read_private(task)
      _github                     = self
      _task                       = task
      #determine if the user in question is a collaborator on the repo
      _github.verify_collaborator   _task
      #add key, clone repo, go to specific revision, execute command
      _cmd                        = "export GIT_SSH=#{Github.sh_path} && " +
                                    "cd #{_task.path_dir} && " +
                                    "git clone -q git@#{_github.name.sub("/",":")}.git --depth=1"
      _cmd.popen4(true)
      Logger.write                  "Read private git repo #{_github._id}"
      true
    end
  end
end
