require "mobilize/version"

module Mobilize
  #folder where project is installed
  def Mobilize.root
    ENV['PWD']
  end
  #force Mobilize context when running `bundle console`
  def Mobilize.console
    require 'irb'
    IRB.setup nil
    IRB.conf[:MAIN_CONTEXT] = IRB::Irb.new.context
    require 'irb/ext/multi-irb'
    IRB.irb nil, Mobilize
  end
  def Mobilize.env
    #use MOBILIZE_ENV to manually set your environment when you start your app
    ENV['MOBILIZE_ENV'] || "development"
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
end

require "popen4"
require "mobilize/extensions/string"
require "mobilize/extensions/yaml"

require 'mongoid'
mongoid_config_path = "#{Mobilize.root}/config/mongoid.yml"
Mongoid.load!(mongoid_config_path, Mobilize.env)

models_dir = "mobilize/models"
user_dir = "#{models_dir}/user"
container_dir = "#{models_dir}/container"
path_dir = "#{models_dir}/path"
aws_dir = "#{path_dir}/aws"
google_dir = "#{path_dir}/google"
gbook_dir = "#{google_dir}/gbook"

require "#{user_dir}/user"
require "#{user_dir}/user_cred"
require "#{user_dir}/schedule"
require "#{user_dir}/job"
require "#{user_dir}/stage"
require "#{user_dir}/transfer"

require "#{container_dir}/container"
require "#{container_dir}/image"
require "#{container_dir}/node"

require "#{path_dir}/path"

require "#{path_dir}/git_path"

require "aws"
require "#{aws_dir}/aws_path"
require "#{aws_dir}/ec2_path"
require "#{aws_dir}/hive_path"
require "#{aws_dir}/rds_path"
require "#{aws_dir}/s3_path"

require "gmail"
require "#{google_dir}/gmail_path"

require "google_drive"
require "#{google_dir}/gfile_path"
require "#{gbook_dir}/gbook_path"
require "#{gbook_dir}/gtab_path"
require "#{gbook_dir}/grange_path"
