require "test_helper"
class Ec2Test < MiniTest::Unit::TestCase
  include Mobilize
  def setup
    Mongoid.purge!
    @worker_name               = Mobilize.config.fixture.ec2.worker_name
    @ec2                       = Fixture::Ec2.default @worker_name
    #create session based off of definites
    @ec2_session               = Ec2.session
  end

  #make sure defaults are working as expected
  def test_login
    assert_equal                 @ec2_session.class, Aws::Ec2
  end

  def test_find_or_create_instance
    #make sure all instances with the test name are terminated
    @ec2.purge!                  @ec2_session
    #create new instance
    @ec2                       = Fixture::Ec2.default @worker_name
    @ec2.find_or_create_instance @ec2_session

    assert_equal                 @ec2.instance(@ec2_session)[:aws_state], 
                                 "running"

    #delete DB version, start over, should find existing instance
    #and assign to database object, making them equal
    instance_id                = @ec2.instance_id
    @ec2.delete
    @ec2                       = Fixture::Ec2.default(@worker_name)
    @ec2.find_or_create_instance @ec2_session

    assert_equal                 @ec2.instance_id, instance_id

    #finally, find_or_create_instance should return
    #the same as simply instance
    assert_equal                 @ec2.find_or_create_instance(@ec2_session),
                                 @ec2.instance(@ec2_session)
  end

  def test_purge!
    #make sure the instance is up and running for latest @ec2
    @ec2.find_or_create_instance @ec2_session
    assert_equal                 @ec2.instance(@ec2_session)[:aws_state],
                                 "running"
    @ec2.purge!                  @ec2_session
    #instances array should be empty
    instances                    = Ec2.instances_by_name(@worker_name, @ec2_session)
    assert_equal                 instances, []
  end
end
