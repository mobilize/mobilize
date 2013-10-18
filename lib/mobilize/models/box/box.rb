module Mobilize
  #a Box resolves to an ec2 instance
  class Box
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Ssh
    include Mobilize::Recipe
    field    :name,             type: String
    field    :ami,              type: String, default:->{@@config.ami}
    field    :size,             type: String, default:->{@@config.size}
    field    :keypair_name,     type: String, default:->{@@config.keypair_name}
    field    :security_groups,  type: Array,  default:->{@@config.security_groups}
    field    :instance_id,      type: String
    field    :dns,              type: String #public dns
    field    :ip,               type: String #private ip
    field    :_id,              type: String, default:->{ name }
    has_many :jobs

    index({dns: 1}, {unique: true, name: "dns_index"})

    @@config = Mobilize.config("box")

    def Box.private_key_path;     "#{Config.key_dir}/box.ssh"; end #created during configuration    

    def Box.session
      access_key_id     = Mobilize.config.aws.access_key_id
      secret_access_key = Mobilize.config.aws.secret_access_key
      region            = @@config.region
      @session          = Aws::Ec2.new(access_key_id,secret_access_key,region: region)
      Logger.info         "Got ec2 session for region #{region}"
      return              @session
    end

    def Box.instances(session, params=nil)
      params          ||= {aws_state: ['running','pending']}
      @session          = session
      all_insts         = @session.describe_instances.map{|i| i.with_indifferent_access}
      filtered_insts    = Box.filter_instances(all_insts,params)
      Logger.info         "got #{filtered_insts.length.to_s} " +
                          "instances for #{@session.params[:region]}, " +
                          "params: #{params.to_s}"
      return              filtered_insts
    end

    def Box.filter_instances(all_insts,params=nil)
      params         ||= {aws_state: ['running','pending']}
      #check for params that match inside the selected instances
      all_insts.select do |i|
        match_array         = params.map{|k,v| v.to_a.include?(i[k])}.uniq
        match_array.length == 1 and match_array.first == true
      end
    end

    def Box.instances_by_name(name,session,params=nil)
      params         ||= {aws_state: ['running','pending']}
      @session         = session
      insts            = Box.instances(@session).select{|i| i[:tags][:name] == name}
      Logger.info        "found #{insts.length.to_s} instances by name #{name}"
      return             insts
    end

    def find_or_create_instance(session)
      @box             = self
      @session         = session
      begin
        #check for an instance_id assigned, so verify and
        #update w any changes
        return           @box.instance(@session) if @box.instance_id
      rescue
        #go ahead and create an instance if it turns out this ID is wrong
      end
      #create an instance based on current parameters
      return             @box.create_instance(@session)
    end

    #find instance by ID, update DB record with latest from AWS
    def instance(session)
      @box             = self
      @session         = session
      params           = {aws_instance_id: @box.instance_id,
                          aws_state:       ['running','pending']
                         }
      inst             = Box.instances(@session,params).first
      inst             = @box.create_instance(@session) if inst.nil?
      @box.sync          inst
      return             inst
    end

    def sync(instance)
      @instance            = instance
      @box                 = self
      @box.update_attributes(
        ami:                 @instance[:aws_image_id],
        size:                @instance[:instance_type],
        keypair_name:        @instance[:keypair_name],
        security_groups:     @instance[:group_ids],
        instance_id:         @instance[:aws_instance_id],
        dns:                 @instance[:dns_name],
        ip:                  @instance[:aws_private_ip_address]
      )
      Logger.info            "synced instance #{@box.instance_id} with remote."
      return                 @box
    end

    def purge!(session)
      #terminates the remote instance then
      #deletes the local database instance
      @box                         = self
      @session                     = session
      #terminate instances by name
      insts                        = Box.instances_by_name(@box.name,@session)

      insts.each do |i|
        @session.terminate_instances [i[:aws_instance_id]]
        Logger.info                  "Terminated instance #{i[:aws_instance_id]}"
      end

      @box.delete
      Logger.info                    "Purged #{@box.id} from DB"
      return                         true
    end

    def launch(session)
      @box                        = self
      @session                    = session
      inst_params = {key_name:      @box.keypair_name,
                     group_ids:     @box.security_groups,
                     instance_type: @box.size}

      inst                        = @session.launch_instances(@box.ami, inst_params).first
      @session.create_tag           inst[:aws_instance_id], "name", @box.name
      return                        inst
    end

    def resolve_instance(session)
      @box                        = self
      @session                    = session
      insts                       = Box.instances_by_name(@box.name,@session)

      if                            insts.length>1
        Logger.error                "You have more than 1 running instance named " +
                                    "#{@box.name} -- please investigate your configuration"
      elsif                         insts.length == 1
        inst                      = insts.first
        Logger.info                 "Instance #{inst[:aws_instance_id]} found, assigning to #{@box.name}"
      elsif                         insts.empty?
        inst                      = nil
      end

      return                        inst
    end

    def wait_for_instance(session)
      @box                        = self
      @session                    = session
      state                       = @box.instance(@session)[:aws_state]
      while                         state != "running"
        Logger.info                 "Instance #{@box.instance_id} still at #{state} -- waiting 10 sec"
        sleep                       10
        state                     = @box.instance(@session)[:aws_state]
      end
    end

    def create_instance(session)
      @box                        = self
      @session                    = session
      inst                        = @box.resolve_instance(@session) || @box.launch(@session)
      @box.sync                     inst
      #wait around until the instance is running
      @box.wait_for_instance        @session
      return                        @box.instance(@session)
    end
  end
end
