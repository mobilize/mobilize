module Mobilize
  #an Ec2 resolves to an ec2 instance
  class Ec2
    include Mongoid::Document
    include Mongoid::Timestamps
    field :name, type: String #name tag on the ec2 instance
    field :ami, type: String, default:->{ENV['MOB_EC2_DEF_AMI']}
    field :size, type: String, default:->{ENV['MOB_EC2_DEF_SIZE']}
    field :keypair_name, type: String, default:->{ENV['MOB_EC2_DEF_KEYPAIR_NAME']}
    field :security_group_names, type: Array, default:->{ENV['MOB_EC2_DEF_SG_NAMES'].split(",")}
    field :instance_id, type: String
    field :dns, type: String #public dns
    field :ip, type: String #private ip
    field :_id, type: String, default:->{ name }

    index({dns: 1}, {unique: true, name: "dns_index"})

    after_create :find_or_create_instance

    def Ec2.login(access_key_id=ENV['AWS_ACCESS_KEY_ID'],
                      secret_access_key=ENV['AWS_SECRET_ACCESS_KEY'],
                      region=ENV['MOB_EC2_DEF_REGION'])
      @session = Aws::Ec2.new(access_key_id,secret_access_key,region: region)
      Logger.info("Logged into ec2 for region #{region}")
      return @session
    end

    def Ec2.instances(session=nil, params={aws_state: 'running'})
      @session = session || Ec2.login
      all_insts = @session.describe_instances.map{|i| i.with_indifferent_access}
      filtered_insts = all_insts.select do |i|
        match_array = params.map{|k,v| i[k] == v}.uniq
        match_array.length == 1 and match_array.first == true
      end
      Logger.info("got #{filtered_insts.length.to_s} instances for #{@session.params[:region]}, params: #{params.to_s}")
      return filtered_insts
    end

    def Ec2.instances_by_name(name,session=nil,params={aws_state: 'running'})
      @session = session || Ec2.login
      Logger.info("filtered instances by name #{name}")
      Ec2.instances(@session).select{|i| i[:tags][:name] == name}
    end


    def find_or_create_instance(session=nil)
      @ec2 = self
      @session = session || Ec2.login
      begin
        #check for an instance_id assigned, so verify and
        #update w any changes
        return @ec2.instance(@session) if @ec2.instance_id
      rescue
        #go ahead and create an instance if it turns out this ID is wrong
      end
      #create an instance based on current parameters
      return @ec2.create_instance(@session)
    end

    #find instance by ID, update DB record with latest from AWS
    def instance(session=nil)
      @ec2 = self
      @session = session || Ec2.login
      inst = Ec2.instances(@session,{aws_instance_id: @ec2.instance_id}).first
      @ec2.sync_instance(inst)
      return inst
    end

    def sync_instance(rem_inst)
      @ec2 = self
      @ec2.update_attributes(
        ami: rem_inst[:aws_image_id],
        size: rem_inst[:instance_type],
        keypair_name: rem_inst[:keypair_name],
        security_group_names: rem_inst[:group_ids],
        instance_id: rem_inst[:aws_instance_id],
        dns: rem_inst[:dns_name],
        ip: rem_inst[:aws_private_ip_address]
      )
      Logger.info("synced instance #{@ec2.instance_id} with remote.")
      return @ec2
    end

    def purge!(session=nil)
      #terminates the remote instance then
      #deletes the local database instance
      @ec2 = self
      @session = session || Ec2.login
      #terminate instances by name
      insts = Ec2.instances_by_name(@ec2.name,@session)
      insts.each do |i|
        @session.terminate_instances([i[:aws_instance_id]])
        Logger.info("Terminated instance #{i[:aws_instance_id]}")
      end
      if @ec2.created_at
         Logger.info("Purged #{@ec2.name} from DB")
         @ec2.delete
      end
      return true
    end

    def create_instance(session=nil)
      @ec2 = self
      @session = session || Ec2.login
      insts = Ec2.instances_by_name(@ec2.name,@session)
      if insts.length>1
        Logger.error("You have more than 1 running instance named #{@ec2.name} -- please investigate your configuration")
      elsif insts.length == 1
        inst = insts.first
        Logger.info("Instance #{inst[:aws_instance_id]} found, assigning to #{@ec2.name}")
      elsif insts.empty?
        #create new instance
        inst_params = {key_name: @ec2.keypair_name, group_ids: @ec2.security_group_names, instance_type: @ec2.size}
        inst = @session.launch_instances(@ec2.ami, inst_params).first
        @session.create_tag(inst[:aws_instance_id],"name", @ec2.name)
      end
      @ec2.sync_instance(inst)
      #wait around until the instance is running
      while (state=@ec2.instance(@session)[:aws_state]) != "running"
        Logger.info("Instance #{@ec2.instance_id} still at #{state} -- waiting 10 sec")
        sleep 10
      end
      return @ec2.instance
    end

    def ssh(command,except=true)
      @ec2 = self
      total_retries = ENV['MOB_EC2_SSH_TOTAL_RETRIES'] || 5
      @result = nil
      @exc = nil
      retries = 0
      while retries < total_retries and @result.nil?
        begin
          Net::SSH.start(@ec2.dns,ENV['MOB_EC2_ROOT_USER'],:keys=>ENV['MOB_EC2_PRIV_KEY_PATH']) do |ssh|
            @result = ssh.run(command,except)
          end
        rescue => @exc
          retries += 1
          Logger.info("Failed #{command} on #{@ec2.name} with #{@exc.to_s}")
          Logger.info("Retrying #{command} on #{@ec2.name} #{retries.to_s} of #{total_retries.to_s} time(s)")
        end
      end
      if @result.nil?
        Logger.error("Unable to run #{command} on #{@ec2.name} with #{@exc.to_s}")
      else
        Logger.info("Ran #{command} on #{@ec2.name}")
      end
      return @result
    end

    def scp(loc_path, rem_path)
      @ec2 = self
      total_retries = ENV['MOB_EC2_SSH_TOTAL_RETRIES'] || 5
      @result = nil
      @exc = nil
      retries = 0
      while retries < total_retries and @result.nil?
        begin
          Net::SCP.start(@ec2.dns,ENV['MOB_EC2_ROOT_USER'],:keys=>ENV['MOB_EC2_PRIV_KEY_PATH']) do |scp|
            scp.upload!(loc_path,rem_path) do |ch, name, sent, total|
              Logger.info("#{name}: #{sent}/#{total}")
            end
            @result = true
          end
        rescue => @exc
          retries += 1
          Logger.info("Failed scp from #{loc_path} to #{rem_path} on #{@ec2.name} with #{@exc.to_s}")
          Logger.info("Retrying scp from #{loc_path} to #{rem_path} on #{@ec2.name} #{retries.to_s} of #{total_retries.to_s} time(s)")
        end
      end
      if @result.nil?
        Logger.error("Unable to scp from #{loc_path} to #{rem_path} on #{@ec2.name} with #{@exc.to_s}")
      else
        Logger.info("Ran scp from #{loc_path} to #{rem_path} on #{@ec2.name}")
      end
      return @result
    end
  end
end
