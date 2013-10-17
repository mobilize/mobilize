require "test_helper"
class BoxTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @Fixture                   = Mobilize::Fixture
    @Box                       = Mobilize::Box
    @worker_name               = Mobilize.config.fixture.box.worker_name
    @box                       = @Fixture::Box.default @worker_name
    #create session based off of definites
    @box_session               = @Box.session
  end

  #make sure defaults are working as expected
  def test_login
    assert_equal                 @box_session.class, Aws::Ec2
  end

  def test_find_or_create_instance
    #make sure all instances with the test name are terminated
    @box.purge!                  @box_session
    #create new instance
    @box                       = @Fixture::Box.default @worker_name
    @box.find_or_create_instance @box_session

    assert_equal                 @box.instance(@box_session)[:aws_state], 
                                 "running"

    #delete DB version, start over, should find existing instance
    #and assign to database object, making them equal
    instance_id                = @box.instance_id
    @box.delete
    @box                       = @Fixture::Box.default(@worker_name)
    @box.find_or_create_instance @box_session

    assert_equal                 @box.instance_id, instance_id

    #finally, find_or_create_instance should return
    #the same as simply instance
    assert_equal                 @box.find_or_create_instance(@box_session),
                                 @box.instance(@box_session)
  end

  def test_purge!
    #make sure the instance is up and running for latest @box
    @box.find_or_create_instance @box_session
    assert_equal                 @box.instance(@box_session)[:aws_state],
                                 "running"
    @box.purge!                  @box_session
    #instances array should be empty
    instances                    = @Box.instances_by_name(@worker_name, @box_session)
    assert_equal                 instances, []
  end
end
