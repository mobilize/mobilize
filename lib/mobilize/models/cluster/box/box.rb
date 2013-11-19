module Mobilize
  #a Box resolves to an ec2 remote
  class Box
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Box::Action
    field    :name,             type: String
    field    :ami,              type: String, default:->{ @@config.ami }
    field    :size,             type: String, default:->{ @@config.size }
    field    :keypair_name,     type: String, default:->{ @@config.keypair_name }
    field    :security_groups,  type: Array,  default:->{ @@config.security_groups }
    field    :remote_id,        type: String
    field    :dns,              type: String #public dns
    field    :ip,               type: String #private ip
    field    :hostname,         type: String
    field    :_id,              type: String, default:->{ name }
    has_many :jobs

    @@config                     = Mobilize.config.cluster.box

    after_initialize :set_self
    def set_self ; @box = self ; end

    def user_name ;                 @@config.user_name ; end

    def home_dir ;                  "/home/#{ self.user_name }" ; end

    def mobilize_home_dir ;        "#{ self.home_dir }/.mobilize" ; end

    def mobilize_config_dir ;      "#{ self.mobilize_home_dir }/config" ; end

    def key_dir ;                  "#{ self.mobilize_home_dir }/keys" ; end

    def Box.private_key_path ;     "#{ Config.key_dir }/box.ssh" ;  end #created during configuration    

    def Box.session

      _access_key_id     = Mobilize.config.aws.access_key_id
      _secret_access_key = Mobilize.config.aws.secret_access_key
      _region            = @@config.region
      _session           = Aws::Ec2.new _access_key_id, _secret_access_key,
                                region: _region, logger: Logger.new( '/dev/null' )

      Log.write            "Got ec2 session for region #{_region}"

      _session
    end

    def Box.remotes( _params = nil, _session = Box.session )

      _params            ||= { aws_state: [ 'running', 'pending' ] }

      _remotes           = _session.describe_instances.map { |_remote| _remote.with_indifferent_access }
      #check for params that match inside the selected remotes
      _remotes           = _remotes.hash_match _params

      Log.write           "#{ _remotes.length.to_s } " +
                          "remotes for #{ _session.params[ :region ] }, " +
                          "params: #{ _params.to_s }"
      _remotes
    end

    def Box.remotes_by_name( _name, _params = nil, _session = Box.session )

      _params                  ||= { aws_state: [ 'running', 'pending' ] }

      _remotes                 = Box.remotes( _params, _session ).select { |_remote| _remote[ :tags ][ :Name ] == _name }

      Log.write                  "#{ _remotes.length.to_s } remotes by name #{ _name }"
      _remotes
    end

    #creates both DB box and its remote
    def Box.find_or_create_by_name( _name, _session = Box.session )

      _Box                  = self

      _box                  = _Box.find_or_create_by name: _name

      _remote               = _box.remote( _session ) if _box.remote_id
      _remotes              = if _remote.nil?
                                _Box.remotes_by_name   _name, nil, _session
                              end
      unless                  _remotes.blank?
        _remote             = _remotes.first

        if                    _remotes.length > 1
          Log.write          "TOO MANY REMOTES: #{ _remotes.length } remotes named #{ _name }", "WARN", _box
        end
      end

      if                      _remote
        _box.sync             _remote
      else
        _box.launch           _session
      end
    end

    def Box.find_self
      Box.where( hostname: Socket.gethostname ).first
    end

    def remote( _session = Box.session )
      Log.write(        "Box has no remote_id", "FATAL", @box ) unless @box.remote_id

      _remotes         = Box.remotes_by_name @box.name,
                                             { aws_state:       [ 'running', 'pending' ],
                                               aws_instance_id: @box.remote_id },
                                             _session
      _remote          = _remotes.first
      Log.write(         "Found remote #{ @box.remote_id } for #{ @box.id }," +
                         " currently #{ _remote[ :aws_state ] }", "INFO", @box ) if _remote
      _remote
    end

    def sync( _remote )
      _ip   = _remote[ :aws_private_ip_address ]

      @box.update_attributes(
        ami:                 _remote[ :aws_image_id ],
        size:                _remote[ :aws_instance_type ],
        keypair_name:        _remote[ :ssh_key_name ],
        security_groups:     _remote[ :aws_groups ],
        remote_id:           _remote[ :aws_instance_id ],
        dns:                 _remote[ :dns_name ],
        ip:                  _remote[ :aws_private_ip_address ],
        hostname:            "ip-#{ _ip.gsub ".", "-" }"
      )
      Log.write              "synced with remote #{ @box.remote_id }", "INFO", @box
      @box
    end
  end
end
