module Mobilize
  module Recipe
    def install(script,message=nil)
      @ssh, @message, @script   = self, message, script
      Logger.info(@message)    if @message
      @ssh.sh                     @script
      return true
    end
    def install_rvm
      @ssh            = self
      @ssh.install      '\curl -L https://get.rvm.io | bash -s stable --ruby=1.9.3',
                        "Installing RVM and Ruby 1.9.3 on #{@ssh.ec2.id}"
    end
    def install_git
      @ssh            = self
      @ssh.install      "sudo apt-get install -y git",
                        "Installing git on #{@ssh.ec2.id}"
    end
    #take all envs that start with MOB and write them to a file on the engine
    def write_mobrc
      @ssh                  = self

      @mobrc_path           = @ssh.mobilize_dir + "/mobrc"

      @mob_envs             = ENV.select{|key,value|
                                          key.starts_with? "MOB"}

      @mobrc_string         = @mob_envs.map{|key,value|
                                            %{export #{key}=#{value}}
                                           }.join("\n")

      @ssh.write              @mobrc_string, @mobrc_path
      return true
    end
    def upload_keys
      @ssh    = self
      @ssh.cp   Config.key_dir, @ssh.key_dir
    end
    def clone_mobilize
      @ssh                   = self
      @clone_cmd             = "git clone http://u:p@github.com/mobilize/mobilize.git"
      @ssh.sh                  @clone_cmd
    end
    def install_mobilize_gem
      @ssh                   = self
      @ssh.clone_mobilize
      @install_cmd           = "bash -l -c 'cd mobilize && bundle install && rake install'"
      @ssh.sh                  @install_cmd
    end
    def install_mobilize
      @ssh                           = self
      @ssh.ec2.find_or_create_instance Ec2.session
      @ssh.install_rvm
      @ssh.install_git
      @ssh.write_mobrc
      @ssh.upload_keys
      @ssh.install_mobilize_gem
    end
  end
end
