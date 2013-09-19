module Mobilize
  module Config
    def Config.load!
      #goes through ~/.mobrc file
      mob_yml_path = File.expand_path("~/.mob.yml")
      unless File.exists?(mob_yml_path)
        Logger.error("no ~/.mob.yml file found; please run `mob configure` to set up a default file, " +
              "and be sure to populate values appropriate to your setup")
      end
    end

    def Config.local_cache
      ENV['MOB_LOCAL_TMP_DIR'] || "#{Mobilize.root}/tmp"
    end
    def Config.remote_cache
      ENV['MOB_REMOTE_TMP_DIR'] || "/tmp"
    end
    module Ec2
      def Ec2.root_user
        ENV['MOB_EC2_ROOT_USER'] || "ubuntu"
      end
      def Ec2.default_ami
        ENV['MOB_EC2_DEF_AMI'] || Logger.error("You must specify ENV['MOB_EC2_DEF_AMI']")
      end
      def Ec2.default_size
        ENV['MOB_EC2_DEF_SIZE'] || Logger.error("You must specify ENV['MOB_EC2_DEF_SIZE']")
      end
      def Ec2.default_keypair_name
        ENV['MOB_EC2_DEF_KEYPAIR_NAME'] || Logger.error("You must specify ENV['MOB_EC2_DEF_KEYPAIR_NAME']")
      end
      def Ec2.default_security_groups
        sg_names = ENV['MOB_EC2_DEF_SG_NAMES']
        sg_names || Logger.error("You must specify ENV['MOB_EC2_DEF_SG_NAMES']")
        sg_names.split(",")
      end
      def Ec2.default_region
        ENV['MOB_EC2_DEF_REGION'] || Logger.error("You must specify ENV['MOB_EC2_DEF_REGION']")
      end
      def Ec2.private_key_path
        ENV['MOB_EC2_PRIV_KEY_PATH'] || Logger.error("You must specify ENV['MOB_EC2_PRIV_KEY_PATH']")
      end
    end
    module Aws
      def Aws.access_key_id
        ENV['AWS_ACCESS_KEY_ID'] || Logger.error("You must specify ENV['AWS_ACCESS_KEY_ID']")
      end
      def Aws.secret_access_key
        ENV['AWS_SECRET_ACCESS_KEY'] || Logger.error("You must specify ENV['AWS_SECRET_ACCESS_KEY']")
      end
    end
    module Github
      def Github.owner_login
        ENV['MOB_OWNER_GITHUB_LOGIN'] || Logger.error("You must specify ENV['MOB_OWNER_GITHUB_LOGIN']")
      end
      def Github.owner_password
        ENV['MOB_OWNER_GITHUB_PASSWORD'] || Logger.error("You must specify ENV['MOB_OWNER_GITHUB_PASSWORD']")
      end
      def Github.owner_ssh_key_path
        ENV['MOB_OWNER_GITHUB_SSH_KEY_PATH'] || Logger.error("You must specify ENV['MOB_OWNER_GITHUB_SSH_KEY_PATH']")
      end
    end
    module Object
      def Object.send_total_retries
        ENV['MOB_SEND_TOTAL_RETRIES'] || 5
      end
    end
  end
end
