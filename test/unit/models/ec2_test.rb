require "test_helper"
class Ec2Test < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @ec2_params={
      name:Config::Minitest::Ec2.worker_name
    }
    @ec2 = Mobilize::Ec2.new(@ec2_params)
    #create session based off of definites
    @session = Mobilize::Ec2.login
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
