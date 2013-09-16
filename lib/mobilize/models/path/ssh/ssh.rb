module Mobilize
  class Ssh
    include Mongoid::Document
    include Mongoid::Timestamps
    #ssh resolves to an ssh instance in a user's home dir for a given ec2 node
    field :ec2_id, type: String
    field :user_id, type: String
    field :_id, type: String, default:->{ "#{ec2_id}:#{user_ssh_name}" }

    #after_create :find_or_create_home

    def user_ssh_name
      @ssh = self
      return @ssh.user_id.gsub("@","-")
    end

    def ec2
      @ssh = self
      Ec2.find(@ssh.ec2_id)
    end

    def user
      @ssh = self
      User.find(@ssh.user_id)
    end

    def home_dir
      @ssh = self
      return "/home/#{@ssh.user_ssh_name}"
    end

    #logs into the instance using the owner account
    def login
      @ssh = self
      @ec2 = @ssh.ec2
      @session = Net::SSH.start(@ec2.dns,ENV['MOB_EC2_ROOT_USER'],:keys=>ENV['MOB_EC2_PRIV_KEY_PATH'])
      Logger.info("Started SSH session for #{@user.id} on #{@ec2.name}")
      return @session
    end

    #gets a list of deploys for
    #this user on this node
    def deploys(limit=50)
      @ssh = self
      Deployment.where(ssh_id: @ssh.id).to_a
    end

    def deploy(command,files=[],run_params={})
      @ssh = self
      #replace any params in the file_hash and command
      run_params.each do |k,v|
        command.gsub!("@#{k}",v)
        files.each do |name,data|
          data.gsub!("@#{k}",v)
        end
      end
      #make sure the dir for this command is unique
      unique_name = if stage_path
                     stage_path.downcase.alphanunderscore
                   else
                     [user_name,node,command,file_hash.keys.to_s,Time.now.to_f.to_s].join.to_md5
                   end
      fire_cmd = @ssh.deploy(node, user_name, unique_name, command, file_hash)
      result = Ssh.fire!(node,fire_cmd)
      #clear out the md5 folders and those not requested to keep
      s = Stage.find_by_path(stage_path) if stage_path
      unless s and s.params['save_logs']
        rm_cmd = "sudo rm -rf /home/#{user_name}/mobilize/#{unique_name}"
        Ssh.fire!(node,rm_cmd)
      end
      return result
    end
  end
end
