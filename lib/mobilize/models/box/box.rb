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

      Log.write            "Got ec2 session for region #{_region}"

      _session
    end

    def Box.remotes(_params = nil, _session = Box.session)

      _params            ||= {aws_state: ['running','pending']}

      _remotes           = _session.describe_instances.map{|_remote| _remote.with_indifferent_access }
      #check for params that match inside the selected remotes
      _remotes           = _remotes.select do  |_remote|
                             _matches         = _params.map{|_key, _value|
                                                                 _value.to_a.include? _remote[_key]
                                                               }.uniq
                             #return remotes that match
                             _matches.length == 1 and
                             _matches.first  == true
      end

      Log.write           "#{_remotes.length.to_s} " +
                          "remotes for #{_session.params[:region]}, " +
                          "params: #{_params.to_s}"
      _remotes
    end

    def Box.remotes_by_name(_name, _params = nil, _session = Box.session)

      _params                  ||= {aws_state: ['running','pending']}

      _remotes                 = Box.remotes(_params, _session).select{|_remote| _remote[:tags][:Name] == _name}

      Log.write                  "#{_remotes.length.to_s} remotes by name #{_name}"

      _remotes
    end

    #creates both DB box and its remote
    def Box.find_or_create_by_name(_name, _session = Box.session)

      _box                  = Box.find_or_create_by name: _name

      _remote               = _box.remote(_session) if _box.remote_id
      _remotes              = if _remote.nil?
                                Box.remotes_by_name   _name, nil, _session
                              end
      unless                  _remotes.blank?
        _remote             = _remotes.first

        if                    _remotes.length > 1
          Log.write          "TOO MANY REMOTES: #{_remotes.length} remotes named #{_name}", "WARN"
        end
      end

      if                      _remote
        _box.sync             _remote
      else
        _box.launch           _session
      end
    end

    def Box.engine_names
      _engine_boxes = Mobilize.config.engine.boxes
      _engine_boxes.times.map do |_box_i|
                                  "mobilize-engine-#{Mobilize.env}-" +
                                 (_box_i + 1).to_s.rjust(2,'0')
                              end
    end

    def Box.cluster_procs(_engine_calls, _master_calls = [])
      _engine_procs = Box.engine_names.map do |_engine_name|
                      Proc.new{                _engine_box = Box.find_or_create_by_name _engine_name

                                              [_engine_calls].flatten.each{|_engine_call|
                                               _engine_box           .send  _engine_call}
                              }
                                           end
      _master_proc  = Proc.new{                   _master_box = Box.find_or_create_by_name "mobilize-master-#{Mobilize.env}"
                                                 [_master_calls].flatten.each{|_master_call|
                                                  _master_box           .send  _master_call}
                              }
      _cluster_procs = _engine_procs + [_master_proc]
      _cluster_procs
    end

    #installs as many engines as specified in config as well as master
    def Box.install_cluster
      _cluster_procs    = Box.cluster_procs("install_engine", "install_master")
      _result           = _cluster_procs.thread
      _result
    end

    def Box.start_cluster
      _cluster_procs    = Box.cluster_procs("start_engine")
      _result           = _cluster_procs.thread
      _result
    end

    def Box.stop_cluster
      _cluster_procs    = Box.cluster_procs("stop_engine")
      _result           = _cluster_procs.thread
      _result
    end

    def Box.terminate_cluster
      _cluster_procs    = Box.cluster_procs("terminate","terminate")
      _result           = _cluster_procs.thread
      _result
    end

    def remote(_session = Box.session)
      _box             = self

      Log.write(        "Box has no remote_id", "FATAL") unless _box.remote_id

      _remotes         = Box.remotes_by_name _box.name,
                                             {aws_state:       ['running','pending'],
                                              aws_instance_id: _box.remote_id},
                                             _session
      _remote          = _remotes.first
      Log.write(         "Found remote #{_box.remote_id} for #{_box.id}," +
                         " currently #{_remote[:aws_state]}") if _remote
      _remote
    end

    def sync(_remote)
      _box                 = self

      _box.update_attributes(
        ami:                 _remote[:aws_image_id],
        size:                _remote[:aws_instance_type],
        keypair_name:        _remote[:ssh_key_name],
        security_groups:     _remote[:aws_groups],
        remote_id:           _remote[:aws_instance_id],
        dns:                 _remote[:dns_name],
        ip:                  _remote[:aws_private_ip_address]
      )
      Log.write              "synced box #{_box.id} with remote #{_box.remote_id}."
      _box
    end

    def terminate(_session = Box.session)
      #terminates the remote then
      #deletes the local database version
      _box                          = self

      if _box.remote_id
        _session.terminate_instances  _box.remote_id
        Log.write                     "Terminated remote #{_box.remote_id} for #{_box.id}"
      end

      _box.delete
      Log.write                       "Deleted #{_box.id} from DB"

      true
    end

    def launch(_session = Box.session)

      _box                         = self

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

    def wait_for_running(_session  = Box.session)
      _box                         = self
      _remote                      = _box.remote _session
      while                         _remote[:aws_state] != "running"
        Log.write                   "remote #{_box.remote_id} still at #{_remote[:aws_state]} -- waiting 10 sec"
        sleep                       10
        _remote                   = _box.remote _session
      end
      _remote
    end
  end
end
