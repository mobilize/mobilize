module Mobilize
  module Recipe
    def install(script,message=nil)
      @box, @message, @script   = self, message, script
      Logger.info(@message)    if @message
      @box.sh                     @script
      return true
    end
    def install_rvm
      @box            = self
      @box.install      '\curl -L https://get.rvm.io | bash -s stable --ruby=1.9.3',
                        "Installing RVM and Ruby 1.9.3 on #{@box.id}"
    end
    def install_git
      @box            = self
      @box.install      "sudo apt-get install -y git",
                        "Installing git on #{@box.id}"
    end
    #take all envs that start with MOB and write them to a file on the engine
    def write_mobrc
      @box                  = self

      @mobrc_path           = @box.mobilize_config_dir + "/mobrc"

      @mob_envs             = ENV.select{|key,value|
                                          key.starts_with? "MOB"}

      @mobrc_string         = @mob_envs.map{|key,value|
                                            %{export #{key}=#{value}}
                                           }.join("\n")

      @box.write              @mobrc_string, @mobrc_path
      return true
    end
    def upload_keys
      @box    = self
      @box.cp   Config.key_dir, @box.key_dir
    end
    def clone_mobilize
      @box                   = self
      @box.install             "git clone http://u:p@github.com/mobilize/mobilize.git",
                               "Cloning Mobilize on #{@box.id}"
    end
    def install_redis_server
      @box                   = self
      @box.install             "sudo apt-get install -y redis-server",
                               "Installing redis-server on #{@box.id}"
      #installation starts redis-server for some reason
      @box.sh                  "ps aux | grep redis-server | awk '{print $2}' | (sudo xargs kill)",
                                false
      return true
    end
    def install_mobilize_gem
      @box                   = self
      @box.clone_mobilize
      @install_cmd           = "bash -l -c 'cd mobilize && bundle install && rake install'"
      @box.sh                  @install_cmd
    end
    def install_mobilize
      @box                           = self
      @box.find_or_create_instance Ec2.session
      @box.install_rvm
      @box.install_git
      @box.install_redis_server
      @box.write_mobrc
      @box.upload_keys
      @box.install_mobilize_gem
    end
    def start_engine
      @box                          = self
      @box.install_mobilize
      @box.write_resque_pool
      @box.write_god_file
      @box.install_god
      @box.start_god
    end
    def write_resque_pool
      @box                          = self
      @resque_pool_path     = @box.mobilize_config_dir + "/mobrc"

      @mob_envs             = ENV.select{|key,value|
                                          key.starts_with? "MOB"}

      @mobrc_string         = @mob_envs.map{|key,value|
                                            %{export #{key}=#{value}}
                                           }.join("\n")

      @box.write              @mobrc_string, @mobrc_path
      return true
 
    end
  end
end
