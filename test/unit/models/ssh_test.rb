require "test_helper"
class SshTest < MiniTest::Unit::TestCase
  def setup
    @ec2_params={
      name:ENV['MOB_TEST_EC2_NAME'],
      ami:ENV['MOB_TEST_EC2_AMI'],
      size:ENV['MOB_TEST_EC2_SIZE'],
      keypair_name:ENV['MOB_TEST_EC2_KEYPAIR_NAME'],
      security_group_names:ENV['MOB_TEST_EC2_SG_NAMES']
    }
    #set global envs from test
    ENV['AWS_ACCESS_KEY_ID']=ENV['MOB_TEST_AWS_ACCESS_KEY_ID']
    ENV['AWS_SECRET_ACCESS_KEY']=ENV['MOB_TEST_AWS_SECRET_ACCESS_KEY']
    ENV['MOB_EC2_DEF_REGION']=ENV['MOB_TEST_EC2_DEF_REGION']
    @ec2 = Mobilize::Ec2.find_or_create_by(@ec2_params)
    #create user from owner
    @u = Mobilize::User.find_or_create_by(
      id: ENV['MOB_TEST_USER_ID'],
      active: true,
      google_login: ENV['MOB_TEST_GOOGLE_LOGIN'],
      github_login: ENV['MOB_TEST_GITHUB_LOGIN'],
      ec2_public_key: `ssh-keygen -y -f #{ENV['MOB_TEST_EC2_PRIV_KEY_PATH']}`.strip
    )
    #set github params
    ENV['MOB_OWNER_GITHUB_LOGIN']=ENV['MOB_TEST_OWNER_GITHUB_LOGIN']
    ENV['MOB_OWNER_GITHUB_PASSWORD']=ENV['MOB_TEST_OWNER_GITHUB_PASSWORD']
    ENV['MOB_OWNER_GITHUB_SSH_KEY_PATH']=ENV['MOB_TEST_OWNER_GITHUB_SSH_KEY_PATH']
    #create ssh instance
    @ssh = Mobilize::Ssh.find_or_create_by(ec2_id: @ec2.id, user_id: @u.id)
  end
end
