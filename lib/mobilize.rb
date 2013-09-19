require "mobilize/version"

module Mobilize
  #folder where project is installed
  def Mobilize.root
    ENV['PWD']
  end
  #force Mobilize context when running `bundle console`
  def Mobilize.console
    Mobilize.pry
  end
  def Mobilize.env
    #use MOBILIZE_ENV to manually set your environment when you start your app
    ENV['MOBILIZE_ENV'] || "development"
  end
  def Mobilize.tmp
    ENV['MOB_TMP_DIR'] || "#{Mobilize.root}/tmp"
  end
  def Mobilize.ec2_root_user
    ENV['MOB_EC2_ROOT_USER'] || "ubuntu"
  end
  def Mobilize.ec2_default_ami
    ENV['MOB_EC2_DEF_AMI'] || Logger.error("You must specify ENV['MOB_EC2_DEF_AMI']")
  end
  def Mobilize.ec2_default_size
    ENV['MOB_EC2_DEF_SIZE'] || Logger.error("You must specify ENV['MOB_EC2_DEF_SIZE']")
  end
  def Mobilize.ec2_default_keypair_name
    ENV['MOB_EC2_DEF_KEYPAIR_NAME'] || Logger.error("You must specify ENV['MOB_EC2_DEF_KEYPAIR_NAME']")
  end
  def Mobilize.ec2_default_security_groups
    sg_names = ENV['MOB_EC2_DEF_SG_NAMES']
    sg_names || Logger.error("You must specify ENV['MOB_EC2_DEF_SG_NAMES']")
    sg_names.split(",")
  end
  def Mobilize.ec2_default_region
    ENV['MOB_EC2_DEF_REGION'] || Logger.error("You must specify ENV['MOB_EC2_DEF_REGION']")
  end
  def Mobilize.ec2_private_key_path
    ENV['MOB_EC2_PRIV_KEY_PATH'] || Logger.error("You must specify ENV['MOB_EC2_PRIV_KEY_PATH']")
  end
  def Mobilize.aws_access_key_id
    ENV['AWS_ACCESS_KEY_ID'] || Logger.error("You must specify ENV['AWS_ACCESS_KEY_ID']")
  end
  def Mobilize.aws_secret_access_key
    ENV['AWS_SECRET_ACCESS_KEY'] || Logger.error("You must specify ENV['AWS_SECRET_ACCESS_KEY']")
  end
  def Mobilize.owner_github_login
    ENV['MOB_OWNER_GITHUB_LOGIN'] || Logger.error("You must specify ENV['MOB_OWNER_GITHUB_LOGIN']")
  end
  def Mobilize.owner_github_password
    ENV['MOB_OWNER_GITHUB_PASSWORD'] || Logger.error("You must specify ENV['MOB_OWNER_GITHUB_PASSWORD']")
  end
  def Mobilize.owner_github_ssh_key_path
    ENV['MOB_OWNER_GITHUB_SSH_KEY_PATH'] || Logger.error("You must specify ENV['MOB_OWNER_GITHUB_SSH_KEY_PATH']")
  end
  def Mobilize.send_total_retries
    ENV['MOB_SEND_TOTAL_RETRIES'] || 5
  end
  def Mobilize.owner
    User.where(is_owner: true).first
  end
  def Mobilize.owner_ssh_key
    File.read(ENV[Mobilize.config[:owner_ssh_key]])
  end
  def Mobilize.config
    yaml_path = "config/mobilize.yml"
    ::YAML.load_file_indifferent(yaml_path)[Mobilize.env]
  end
  def Mobilize.db
    Mongoid.session(:default)[:database].database
  end
end

require 'pry'
require "popen4"
require 'net/ssh'
require 'net/scp'

require 'mongoid'
mongoid_config_path = "#{Mobilize.root}/config/mongoid.yml"
Mongoid.load!(mongoid_config_path, Mobilize.env)

require "mobilize/logger"

deploy_dir = "#{Mobilize.root}/config/deploy"
require "#{deploy_dir}/travis"

extensions_dir = "mobilize/extensions"
require "#{extensions_dir}/object"
require "#{extensions_dir}/string"
require "#{extensions_dir}/yaml"
require "#{extensions_dir}/net-ssh"
require "#{extensions_dir}/class"

models_dir = "mobilize/models"
user_dir = "#{models_dir}/user"
require "#{user_dir}/user"
require "#{user_dir}/schedule"
require "#{user_dir}/job"

path_dir = "#{models_dir}/path"
require "#{path_dir}/path"
require 'github_api'
require "#{path_dir}/github"

require "aws"
amazon_dir = "#{path_dir}/amazon"
require "#{amazon_dir}/ec2"
require "#{amazon_dir}/hive"
require "#{amazon_dir}/rds"
require "#{amazon_dir}/s3"

require "gmail"
google_dir = "#{path_dir}/google"
gbook_dir = "#{google_dir}/gbook"
require "#{google_dir}/gmail"

require "google_drive"
require "#{google_dir}/gfile"
require "#{gbook_dir}/gbook"
require "#{gbook_dir}/gtab"
require "#{gbook_dir}/grange"

require 'optparse'
cli_dir = "mobilize/cli"
require "#{cli_dir}/cli"
