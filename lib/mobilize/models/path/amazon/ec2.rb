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

    after_create :find_or_create_instance

    def Ec2.login(access_key_id=ENV['AWS_ACCESS_KEY_ID'],
                      secret_access_key=ENV['AWS_SECRET_ACCESS_KEY'],
                      region=ENV['MOB_EC2_DEF_REGION'])
      session = Aws::Ec2.new(access_key_id,secret_access_key,region: region)
      return session
    end

    def Ec2.instances(session=nil, params={aws_state: 'running'})
      session ||= Ec2.login
      all_insts = session.describe_instances.map{|i| i.with_indifferent_access}
      filtered_insts = all_insts.select do |i|
        match_array = params.map{|k,v| i[k] == v}.uniq
        match_array.length == 1 and match_array.first == true
      end
      return filtered_insts
    end

    def find_or_create_instance
      ec2 = self
      session = Ec2.login
      if ec2.instance_id
        #already has an instance_id assigned, so verify and
        #update w any changes
        return ec2.instance(session)
      else
        #create an instance based on current parameters
        return ec2.create_instance(session)
      end
    end

    #find instance by ID, update DB record with latest from AWS
    def instance(session=nil)
      ec2 = self
      session ||= Ec2.login
      inst = Ec2.instances(session,{aws_instance_id: ec2[:instance_id]}).first
      ec2.update_attributes(
        ami: inst[:aws_image_id],
        size: inst[:instance_type],
        keypair_name: inst[:keypair_name],
        security_group_names: inst[:group_ids]
      )
      return inst
    end

    def create_instance(session=nil)
      ec2 = self
      session ||= Ec2.login
      curr_insts = Ec2.instances(session).select{|i| i[:tags][:name] == ec2.name}
      if curr_insts.length>1
        Logger.error("You have more than 1 running instance named #{ec2.name} -- please investigate your configuration")
      elsif curr_insts.length == 1
        curr_inst = curr_insts.first
        ec2.update_attributes(instance_id: curr_inst[:aws_instance_id])
      elsif curr_insts.length == 0
        #create new instance
        new_inst_params = {key_name: ec2.keypair_name, group_ids: ec2.security_group_names, instance_type: ec2.size}
        new_inst = session.launch_instances(ec2.ami, new_inst_params).first
        session.create_tag(new_inst[:aws_instance_id],"name", ec2.name)
        ec2.update_attributes(instance_id: new_inst[:aws_instance_id])
      end
      #wait around until the instance is running
      while (state=ec2.instance(session)[:aws_state]) != "running"
        Logger.info("Instance #{ec2.instance_id} still at #{state}- waiting 10 sec")
        sleep 10
      end
      return ec2.instance
    end
  end
end
