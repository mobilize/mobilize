module Mobilize
  #a Box resolves to an ec2 remote
  class Box
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Box::Action
    field    :name,             type: String
    field    :ami,              type: String, default:->{@@config.ami}
    field    :size,             type: String, default:->{@@config.size}
    field    :keypair_name,     type: String, default:->{@@config.keypair_name}
    field    :security_groups,  type: Array,  default:->{@@config.security_groups}
    field    :remote_id,        type: String
    field    :dns,              type: String #public dns
    field    :ip,               type: String #private ip
    field    :_id,              type: String, default:->{ name }
    has_many :jobs

    @@config = Mobilize.config("box")

    def Box.private_key_path;     "#{Config.key_dir}/box.ssh"; end #created during configuration    

    def Box.session

      _access_key_id     = Mobilize.config.aws.access_key_id
      _secret_access_key = Mobilize.config.aws.secret_access_key
      _region            = @@config.region
      _session           = Aws::Ec2.new _access_key_id, _secret_access_key, region: _region

      Logger.write         "Got ec2 session for region #{_region}"

      _session
    end

    def Box.remotes(params = nil, session = nil)

      _params            = params  || {aws_state: ['running','pending']}
      _session           = session ||  Box.session

      _remotes           = _session.describe_instances.map{|remote| remote.with_indifferent_access }
      #check for params that match inside the selected remotes
      _remotes           = _remotes.select do  |remote|
                             _remote          = remote
                             _matches         = _params.map{|key, value|
                                                                 _key, _value = key, value
                                                                 _value.to_a.include? _remote[_key]
                                                               }.uniq
                             #return remotes that match
                             _matches.length == 1 and
                             _matches.first  == true
      end

      Logger.write        "#{_remotes.length.to_s} " +
                          "remotes for #{_session.params[:region]}, " +
                          "params: #{_params.to_s}"
      _remotes
    end

    def Box.remotes_by_name(name, params = nil, session = Box.session)

      _name                    = name
      _params                  = params  || {aws_state: ['running','pending']}
      _session                 = session || Box.session

      _remotes                 = Box.remotes(_params, _session).select{|remote| remote[:tags][:Name] == _name}

      Logger.write               "#{_remotes.length.to_s} remotes by name #{_name}"

      _remotes
    end

    #creates both DB box and its remote
    def Box.find_or_create_by_name(name, session = nil)

      _name, _session       = name, (session || Box.session)

      _box                  = Box.find_or_create_by name: _name

      _remote               = _box.remote(_session) if _box.remote_id
      _remotes              = if _remote.nil?
                                Box.remotes_by_name   _name, nil, _session
                              end
      unless                  _remotes.blank?
        _remote             = _remotes.first

        if                    _remotes.length > 1
          Logger.write       "TOO MANY REMOTES: #{_remotes.length} remotes named #{_name}", "WARN"
        end
      end

      if                      _remote
        _box.sync             _remote
      else
        _box.launch           _session
      end
    end

    def remote(session = nil)
      _box             = self
      _session         = session || Box.session

      Logger.write(     "Box has no remote_id", "FATAL") unless _box.remote_id

      _remotes         = Box.remotes_by_name _box.name,
                                             {aws_state:       ['running','pending'],
                                              aws_instance_id: _box.remote_id},
                                             _session
      _remote          = _remotes.first
      Logger.write(      "Found remote #{_box.remote_id} for #{_box.id}," +
                         " currently #{_remote[:aws_state]}") if _remote
      _remote
    end

    def sync(remote)
      _box, _remote        = self, remote

      _box.update_attributes(
        ami:                 _remote[:aws_image_id],
        size:                _remote[:aws_instance_type],
        keypair_name:        _remote[:ssh_key_name],
        security_groups:     _remote[:aws_groups],
        remote_id:           _remote[:aws_instance_id],
        dns:                 _remote[:dns_name],
        ip:                  _remote[:aws_private_ip_address]
      )
      Logger.write           "synced box #{_box.id} with remote #{_box.remote_id}."
      _box
    end

    def terminate(session = nil)
      #terminates the remote then
      #deletes the local database version
      _box                          = self
      _session                      = session || Box.session

      if _box.remote_id
        _session.terminate_instances  _box.remote_id
        Logger.write                  "Terminated remote #{_box.remote_id} for #{_box.id}"
      end

      _box.delete
      Logger.write                    "Deleted #{_box.id} from DB"

      true
    end

    def launch(session = nil)

      _box, _session               = self, (session || Box.session)

      _remote_params               = {key_name:      _box.keypair_name,
                                      group_ids:     _box.security_groups,
                                      instance_type:   _box.size}

      _remotes                     = _session.launch_instances(_box.ami, _remote_params)
      _remote                      = _remotes.first

      _box.update_attributes         remote_id: _remote[:aws_instance_id]
      _session.create_tag            _box.remote_id, "Name", _box.name
      _remote                      = _box.wait_for_running _session
      _box.sync                      _remote
    end

    def wait_for_running(session  = nil)
      _box, _session              = self, ( session || Box.session )
      _remote                     = _box.remote _session
      while                         _remote[:aws_state] != "running"
        Logger.write                "remote #{_box.remote_id} still at #{_remote[:aws_state]} -- waiting 10 sec"
        sleep                       10
        _remote                   = _box.remote _session
      end
      _remote
    end
  end
end
