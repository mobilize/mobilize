module Mobilize
  class Ec2Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :service, type: String, default:->{"ec2"}
    field :container_name, type: String
    field :file_path, type: String

    def Ec2Path.login
      session = Aws::Ec2.new(ENV['AWS_ACCESS_KEY_ID'],ENV['AWS_SECRET_ACCESS_KEY'], :region=>ENV['MOB_AWS_REGION'])
      return session
    end

    def Ec2Path.instances(params={state: 'running'})
      all_instances = Ec2Path.login.describe_instances.map{|i| i.with_indifferent_access}
      if params[:state]!='all'
        all_instances.select{|i| i[:aws_state]==params[:state]}
      end
    end

    def Ec2Path.find_or_create_master
      master_instances = Ec2Path.instances.select{|i| i[:tags][:name]==ENV['MOB_AWS_MASTER_NAME']}
      if master_instances.length>1
        raise "You have more than 1 master -- please investigate your configuration"
      elsif master_instances.length==1
        master_instance=master_instances.first
      else
        session = Ec2Path.login
        master_instances = session.launch_instances(ENV['MOB_AWS_MASTER_AMI'],{
          key_name: ENV['MOB_AWS_KEYPAIR_NAME'],
          group_ids: [ENV['MOB_AWS_MASTER_SG_NAME']],
          instance_type: ENV['MOB_AWS_MASTER_SIZE']
        })
        master_instance=master_instances.first
        session.create_tag(master_instance[:aws_instance_id],"name",ENV['MOB_AWS_MASTER_NAME'])
      end
      master_instance
    end

  end
end
