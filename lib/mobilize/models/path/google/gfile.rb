module Mobilize
  class Gfile < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :remote_id,   type: String
    field :name,        type: String
    field :owner,       type: Array
    field :readers,     type: Array
    field :writers,     type: Array
    field :_id,         type: String, default:->{"gfile/#{ owner.alphanunder }/#{ name }"}

    @@config             = Mobilize.config "google"

    after_initialize       :set_self
    def set_self;          @gfile = self;end

    def Gfile.get_password( _email )

      if _email         == @@config.owner.email
        _password        = @@config.owner.password
        Log.write          "Got password for google owner email #{ _email }"
      else
        _password        = @@config.worker.accounts.select{|w| w.email == _email }.first
        if _password
          Log.write        "Got password for google worker email #{ _email }"
        else
          Log.write        "Could not find password for email #{ _email }", "FATAL"
        end
      end
      _password
    end

    def Gfile.session( _email = @@config.owner.email )

      _password       = Gfile.get_password _email

      _session        = ::GoogleDrive.login _email, _password

      Log.write         "Logged into Google Drive."
      _session
    end

    def sync( _remote )
      _roles                          = @gfile.roles _remote

      @gfile.update_attributes name:        _remote.title,
                               remote_id:   _remote.resource_id,
                               owner:       _roles[ :owner ].first,
                               readers:     _roles[ :reader ],
                               writers:     _roles[ :writer ]
      @gfile
    end

    #delete remote and local db object
    def terminate( _session = Gfile.session )
      _remote               = @gfile.remote _session
      Log.write               "Deleting remote #{ _remote.resource_id } for #{ @gfile.id }"

      _remote.delete
      @gfile.delete
      Log.write               "Purged #{ @gfile.id } from DB"

      true
    end

    def launch ( _session = Gfile.session )
      _remote                     = _session.upload_from_string "", @gfile.name
      Log.write                     "Lauched remote #{ _remote.resource_id } for #{ @gfile.id }"
      @gfile.sync                   _remote
    end

    def is_reader?( _user )
      _user.google_login == @gfile.owner or
        @gfile.readers.include? _user.google_login
    end

    def is_writer?( _user )
      _user.google_login == @gfile.owner or
        @gfile.writers.include? _user.google_login
    end

    def read( _task )
      _user                        = _task.user

      _remote                      = @gfile.remote _task.session

      if @gfile.is_reader?           _user
        #make sure path exists but dir does not
        _task.refresh_dir

        _remote.download_to_file   "#{ _task.dir }/stdout"
        Log.write                  "Downloaded #{ @gfile.id } to #{ _task.dir }"
        Log.write                  "#{ _user.google_login }: " +
                                   "#{ File.size( "#{ _task.dir }/stdout" ).to_s } bytes",
                                   "STAT"
      else
        Log.write                  "User #{ _user.id } does not have read access to #{ @gfile.id }", "FATAL"
      end
    end

    def write( _task )
      _user                        = _task.user

      _remote                      = @gfile.remote _task.session

      if @gfile.is_writer?           _user

        _source                    = _task.source
        _remote.update_from_string   _source
        Log.write                    "Uploaded #{ _task.input } to #{ @gfile.id }"
        Log.write                    "#{ _user.google_login }: #{ _task.source.length } bytes", "STAT"
      else
        Log.write                    "#{ _user.google_login } does not have write access to #{ @gfile.id }", "FATAL"
      end
      true
    end

    def Gfile.remotes_by( _session = Gfile.session, _params = {} )

      if _params[ :title ]
         _params[ "title-exact" ]          = true
      end

      _remotes                             = _session.files _params
      #sort by published date for seniority
      _remotes.sort_by {|remote|
                        _remote            = remote
                        _publish_element   = _remote.document_feed_entry.css "published"
                        _publish_timestamp = _publish_element.children.first.text
                        _publish_timestamp
                        }
    end

    #creates both file and its remote
    def Gfile.find_or_create_by_owner_and_name( _owner, _name, _session = Gfile.session )

      @gfile                      = Gfile.find_or_create_by owner: _owner, name: _name

      _remote                     = @gfile.remote( _session ) if @gfile.remote_id
      _remotes                    = if _remote.nil?
                                      Gfile.remotes_by _session, owner: _owner, title: _name
                                    end

      unless                        _remotes.blank?
        _remote                   = _remotes.first

        if                          _remotes.length > 1
        Log.write(                  "TOO MANY REMOTES: #{ _remotes.length } remotes " +
                                    "by #{ @gfile.owner } with name #{ @gfile.name }", "WARN")
        end
      end

      if                            _remote
        @gfile.sync                 _remote
      else
        @gfile.launch               _session
      end
    end

    def remote( _session = Gfile.session )
      Log.write(           "Gfile has no remote_id", "FATAL" ) unless @gfile.remote_id

      _remotes            = Gfile.remotes_by _session, owner: @gfile.owner, title: @gfile.name

      _remotes            = _remotes.select { |_remote| _remote.resource_id == @gfile.remote_id}
      _remotes.first
    end

    def roles( _remote )
      _acls                       = _remote.acl.to_enum.to_a
      _roles                      = { owner: [], reader: [], writer: [] }
      _acls.each                do |_acl|
        _scope                    = if _acl.scope.nil?
                                       _acl.with_key ? "link" : "everyone"
                                   else
                                       _acl.scope
                                   end
        _sym_role                = _acl.role.to_sym
        _roles[ _sym_role ]      << _scope
      end
      _roles
    end
  end
end
