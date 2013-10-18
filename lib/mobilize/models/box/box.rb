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

      @access_key_id     = Mobilize.config.aws.access_key_id
      @secret_access_key = Mobilize.config.aws.secret_access_key
      @region            = @@config.region
      @session           = Aws::Ec2.new @access_key_id, @secret_access_key, region: @region

      Logger.write         "Got ec2 session for region #{@region}"

      @session
    end

    def Box.remotes(params = nil, session = nil)

      @params            = params  || {aws_state: ['running','pending']}
      @session           = session ||  Box.session

      @remotes           = @session.describe_instances.map{|remote| remote.with_indifferent_access }
      #check for params that match inside the selected remotes
      @remotes           = @remotes.select do  |remote|
                             @remote          = remote
                             @matches         = @params.map{|key, value|
                                                                 @key, @value = key, value
                                                                 @value.to_a.include? @remote[@key]
                                                               }.uniq
                             #return remotes that match
                             @matches.length == 1 and
                             @matches.first  == true
      end

      Logger.write        "#{@remotes.length.to_s} " +
                          "remotes for #{@session.params[:region]}, " +
                          "params: #{@params.to_s}"
      @remotes
    end

    def Box.remotes_by_name(name, params = nil, session = Box.session)

      @name                    = name
      @params                  = params  || {aws_state: ['running','pending']}
      @session                 = session || Box.session

      @remotes                 = Box.remotes(@params, @session).select{|remote| remote[:tags][:name] == @name}

      Logger.write               "#{@remotes.length.to_s} remotes by name #{@name}"

      @remotes
    end

    def Box.sync_or_launch_by_name(name, session = nil)

      @name                 = name
      @session              = session || Box.session

      @box                  = Box.find_or_create_by name: @name
      @remotes              = Box.remotes_by_name   @name, nil, @session

      @remote_index         = @remotes.index{|remote|
                                              remote[:aws_remote_id] == @box.remote_id }

      if                      @remote_index.nil? and !@remotes.empty?
        @remote_index       = 0

        if                  @remotes.length > 1
          Logger.write      "TOO MANY REMOTES: #{@remotes.length} remotes named #{@name}", "WARN"
        end
      end

      if                      @remote_index
        @box.sync             @remotes[@remote_index]
      else
        @box.launch           @session
      end
    end

    def remote(session = nil)
      @box             = self
      Logger.write       "Box has no remote_id" unless @box.remote_id
      @session       ||= session
      @remotes         = Box.remotes_by_name @box.name,
                                             {aws_state:       ['running','pending'],
                                              aws_instance_id: @box.remote_id},
                                             @session
      @remotes.first
    end

    def sync(remote)
      @box, @remote        = self, remote

      @box.update_attributes(
        ami:                 @remote[:aws_image_id],
        size:                @remote[:remote_type],
        keypair_name:        @remote[:keypair_name],
        security_groups:     @remote[:group_ids],
        remote_id:           @remote[:aws_instance_id],
        dns:                 @remote[:dns_name],
        ip:                  @remote[:aws_private_ip_address]
      )
      Logger.write           "synced box #{@box.id} with remote #{@box.remote_id}."
      @box
    end

    def terminate(session = nil)
      #terminates the remote remote then
      #deletes the local database remote
      @box                          = self
      @session                    ||= Box.session
      #terminate remotes by name
      @remotes                      = Box.remotes_by_name @box.name,nil, @session

      @remotes.each do |remote|

        @session.terminate_instances  remote[:aws_instance_id].to_a

        Logger.write                  "Terminated remote #{remote[:aws_instance_id]}"

      end

      @box.delete

      Logger.write                    "Deleted #{@box.id} from DB"

      true
    end

    def launch(session = nil)

      @box                         = self

      @session                   ||= Box.session

      @remote_params               = {key_name:      @box.keypair_name,
                                      group_ids:     @box.security_groups,
                                      instance_type:   @box.size}

      @remote                      = @session.launch_instances(@box.ami, @remote_params).first

      @box.update_attributes         remote_id: @remote[:aws_instance_id]
      @session.create_tag            @box.remote_id, "name", @box.name
      @remote                      = @box.wait_for_running @session
      @box.sync                      @remote
    end

    def wait_for_running(session  = nil)
      @box                        = self
      @session                  ||= Box.session
      @remote                     = @box.remote @session
      while                         @remote[:aws_state] != "running"
        Logger.write                "remote #{@box.remote_id} still at #{@remote[:aws_state]} -- waiting 10 sec"
        sleep                       10
        @remote                   = @box.remote @session
      end
      @remote
    end
  end
end
