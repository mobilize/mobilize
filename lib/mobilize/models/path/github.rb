module Mobilize
  class Github < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    #a github points to a specific repo
    field :domain,              type: String, default:->{ "github.com" }
    field :owner_name,          type: String
    field :repo_name,           type: String
    field :name,                type: String, default:->{ "#{ domain }/#{ owner_name }/#{ repo_name }" }
    field :_id,                 type: String, default:->{ "github/#{ name }" }

    @@config                  = Mobilize.config "github"

    def Github.sh_path;         Config.key_dir + "/git.sh"; end

    def Github.session
      _session                = ::Github.new login:    @@config.owner_login,
                                             password: @@config.owner_password
      Log.write                 "Logged into Github."
      _session
    end

    def repo_call( _task, _action, _category = nil )
      _github, _session       = self, Github.session
      begin
        _connection           = _session.repos
        _connection           = _category ? _connection.send( _category ) : _connection
        _response             = _connection.send _action,
                                                 user: _github.owner_name,
                                                 repo: _github.repo_name
        _call                 = [ _action, _category ].compact.join "."
        _calls_left           = _response.headers.ratelimit_remaining
        Log.write               "#{ _call } successful for repo; " +
                                "#{ _calls_left } calls left this hour", "INFO", _github
      rescue
        Log.write               "could not access repository", "FATAL", _github
      end
      _response
    end

    def collaborators( _task )
      _github                 = self
      _response               = _github.repo_call _task,"list","collaborators"
      _collaborators          = _response.body.map { |_section| _section[ :login ] }
      _collaborators
    end

    #clones repo into worker with depth of 1
    #checks out appropriate branch
    #needs user_id with git_ssh_key to get private repo
    def read( _task )
      _github                = self
      _task.refresh_dir
      begin
        Log.write              "attempting public read", "INFO", _github
        _github.read_public    _task
      rescue
        Log.write              "public read failed, attempting private read", "INFO", _github
        _github.read_private   _task
      end
      #get size of objects and log, formatted for no line breaks
      _log_cmd               = "cd #{ _task.dir }/#{ _github.repo_name } && git count-objects -v"

      _size                  = _log_cmd.popen4.split( "\n" ).join ", "

      Log.write                "read into task dir", "INFO", _github

      Log.write                _size, "STAT", _task.user
      #deploy github repo
      true
    end

    def read_public( _task )
      _github                = self
      _cmd                   = "cd #{ _task.dir } && " +
                               "git clone -q https://u:p@#{ _github.name }.git --depth=1"
      _cmd.popen4
      Log.write                "read complete", "INFO", _github
      true
    end

    def verify_collaborator( _task )
      _github                = self
      _user                  = _task.user
      _is_collaborator       = _github.collaborators( _task ).include? _user.github_login

      if _is_collaborator
        Log.write              "#{ _user.id } has access", "INFO", _github
        true
      else
        Log.write              "#{ _user.id } does not have access", "FATAL", _github
      end
    end

    def read_private( _task )
      _github                     = self
      #determine if the user in question is a collaborator on the repo
      _github.verify_collaborator   _task
      #add key, clone repo, go to specific revision, execute command
      _cmd                        = "export GIT_SSH=#{ Github.sh_path } && " +
                                    "cd #{ _task.dir } && " +
                                    "git clone -q git@#{ _github.name.sub "/", ":" }.git --depth=1"
      _cmd.popen4
      Log.write                     "read private repo", "INFO", _github
      true
    end
  end
end
