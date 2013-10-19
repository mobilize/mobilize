module Mobilize
  class Gfile < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :remote_id,   type: String
    field :name,        type: String
    field :owner,       type: Array
    field :readers,     type: Array
    field :writers,     type: Array
    field :_id,         type: String, default:->{"gfile/#{owner.alphanunderscore}/#{name}"}

    @@config             = Mobilize.config("google")

    def Gfile.get_password(email)

      _email             = email

      if _email         == @@config.owner.email
        _password        = @@config.owner.password
        Logger.write       "Got password for google owner email #{_email}"
      else
        _password        = @@config.worker.accounts.select{|w| w.email == _email}.first
        if _password
          Logger.write     "Got password for google worker email #{_email}"
        else
          Logger.write     "Could not find password for email #{_email}", "FATAL"
        end
      end
      _password
    end

    def Gfile.session(email = nil)

      _email          = @@config.owner.email
      _password       = Gfile.get_password _email

      _session        = ::GoogleDrive.login _email, _password

      Logger.write      "Logged into Google Drive."
      _session
    end

    def sync(remote)
      _gfile, _remote                 = self, remote

      _roles                          = _gfile.roles _remote

      _gfile.update_attributes name:    _remote.title,
                               key:     _remote.resource_id,
                               owner:   _roles[:owner].first,
                               readers: _roles[:reader],
                               writers: _roles[:writer]
      _gfile
    end

    #delete remote and local db object
    def terminate(session)
      _gfile, _session      = self, session
      _remote               = _gfile.remote(_session)
      Logger.write            "Deleting remote #{_remote.resource_id} for #{_gfile.id}"

      _remote.delete
      _gfile.delete
      Logger.write            "Purged #{_gfile.id} from DB"

      true
    end

    def launch(session)
      _gfile, _session            = self, session
      _remote                     = _session.upload_from_string("", _gfile.name)
      Logger.write                  "Lauched remote #{_remote.resource_id} for #{_gfile.id}"
      _gfile.sync                   _remote
    end

    def is_reader?(user)
      _gfile, _user               = self, user
      _user.google_login == _gfile.owner or
      _gfile.readers.include? _user.google_login
    end

    def is_writer?(user)
      _user, _gfile                = user, self
      _user.google_login == _gfile.owner or
      _gfile.writers.include? _user.google_login
    end

    def read(task)
      _gfile, _task, _user        = self, task, task.user

      _remote                     = _gfile.sync _task.session

      if _gfile.is_reader?          _user
        #make sure path exists but dir does not
        _task.refresh_dir

        _remote.download_to_file   "#{_task.dir}/stdout"
        Logger.write               "Downloaded #{_gfile.id} to #{_task.dir}/stdout"
        Logger.write               "#{_user.google_login}: #{File.size(_task.input).to_s} bytes", "STAT"
      else
        Logger.write               "User #{_user.id} does not have read access to #{_gfile.id}", "FATAL"
      end
    end

    def write(task)
      _gfile, _task, _user         = self, task, task.user

      _remote                      = _gfile.remote _task.session

      if _gfile.is_writer?           _user

        _remote.update_from_file     _task.input
        Logger.write                 "Uploaded #{_task.input} from #{_gfile.id}"
        Logger.write                 "#{_user.google_login}: #{File.size(_task.input).to_s} bytes", "STAT"
      else
        Logger.write                 "#{_user.google_login} does not have write access to #{_gfile.id}", "FATAL"
      end
      true
    end

    def Gfile.remotes_by(session, params = {})
      _session                             = session

      if params[:title]
        params["title-exact"]              = true
      end

      _remotes                             = _session.files params
      #sort by published date for seniority
      _remotes.sort_by {|remote|
                        _remote            = remote
                        _publish_element   = _remote.document_feed_entry.css("published")
                        _publish_timestamp = _publish_element.children.first.text
                        _publish_timestamp
                        }
    end

    #creates both file and its remote
    def Gfile.find_or_create_by_owner_and_name(owner, name, session)
      _owner, _name, _session     = owner, name, session

      _gfile                      = Gfile.find_or_create_by owner: _owner, name: _name

      _remote                     = _gfile.remote(_session) if _gfile.remote_id
      _remotes                    = if _remote.nil?
                                      Gfile.remotes_by _session, owner: _owner, title: _name
                                    end

      unless                        _remotes.blank?
        _remote                   = _remotes.first

        if                          _remotes.length > 1
        Logger.write(               "TOO MANY REMOTES: #{_remotes.length} remotes " +
                                    "by #{_gfile.owner} with name #{_gfile.name}", "WARN")
        end
      end

      if                            _remote
        _gfile.sync                 _remote
      else
        _gfile.launch               _session
      end
    end

    def remote(session)
      _gfile, _session    = self, session

      Logger.write(        "Gfile has no remote_id", "FATAL") unless _gfile.remote_id

      _remotes            = Gfile.remotes_by(_session, owner: _gfile.owner, title: _gfile.title)

      _remotes            = _remotes.select{|remote|
                                            _remote              = remote
                                            _remote.resource_id == _gfile.remote_id
                                           }
      _remotes.first
    end

    def roles(remote)
      _remote                    = remote
      _acls                      = _remote.acl.to_enum.to_a
      _roles                     = {owner: [], reader: [], writer: []}
      _acls.each                do |acl|
        _acl                     = acl
        _scope                   = if _acl.scope.nil?
                                      _acl.with_key ? "link" : "everyone"
                                   else
                                      _acl.scope
                                   end
        _sym_role                = _acl.role.to_sym
        _roles[_sym_role]       << _scope
      end
      _roles
    end
  end
end
