require "test_helper"
class Ec2Test < MiniTest::Unit::TestCase
  def setup
    @ec2_params={
      name:ENV['MOB_TEST_EC2_NAME'],
      ami:ENV['MOB_TEST_EC2_AMI'],
      size:ENV['MOB_TEST_EC2_SIZE'],
      keypair_name:ENV['MOB_TEST_EC2_KEYPAIR_NAME'],
      security_group_names:ENV['MOB_TEST_EC2_SG_NAMES']
    }
    @ec2 = Mobilize::Ec2.new(@ec2_params)
    #set global envs from test
    ENV['AWS_ACCESS_KEY_ID']=ENV['MOB_TEST_AWS_ACCESS_KEY_ID']
    ENV['AWS_SECRET_ACCESS_KEY']=ENV['MOB_TEST_AWS_SECRET_ACCESS_KEY']
    ENV['MOB_EC2_DEF_REGION']=ENV['MOB_TEST_EC2_DEF_REGION']
    #create session based off of definites
    @session = Mobilize::Ec2.login(ENV['MOB_TEST_AWS_ACCESS_KEY_ID'],
                                   ENV['MOB_TEST_AWS_SECRET_ACCESS_KEY'],
                                   ENV['MOB_TEST_EC2_DEF_REGION'])
  end

  #make sure defaults are working as expected
  def test_login
    assert_equal @session.class, Aws::Ec2
  end

  def test_find_or_create_instance
    #make sure all instances with the test name are terminated
    @ec2.purge!(@session)
    #should create instance on saving @ec2, which triggers after_create
    @ec2.save!
    assert_equal @ec2.instance(@session)[:aws_state], "running"
    #delete DB version, start over, should find existing instance
    #and assign to database object, making them equal
    instance_id = @ec2.instance_id
    @ec2.delete
    @ec2 = Mobilize::Ec2.new(@ec2_params)
    @ec2.save!
    assert_equal @ec2.instance_id, instance_id
    #finally, find_or_create_instance should return
    #the same as simply instance
    assert_equal @ec2.find_or_create_instance(@session), @ec2.instance(@session)
  end

  def test_purge!
    #make sure the instance is up and running for latest @ec2
    @ec2.save!
    assert @ec2.instance(@session)[:aws_state], "running"
    @ec2.purge!(@session)
    assert_equal Mobilize::Ec2.instances_by_name(@ec2_params[:name],@session), []
  end
end
