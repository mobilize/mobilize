require "test_helper"
class BoxTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @Fixture, @Box, @Config    = Mobilize::Fixture, Mobilize::Box, Mobilize.config.fixture
    @box_session               = @Box.session
    @box                       = @Box.find_or_create_by_name @Config.box.name, @box_session
  end

  #make sure defaults are working as expected
  def test_login
    assert_equal                 @box_session.class, Aws::Ec2
  end

  def test_remote
    #make sure all instances with the test name are terminated
    @box.terminate               @box_session
    #create new instance
    @box                       = @Box.find_or_create_by_name @Config.box.name, @box_session

    assert_equal                 @box.remote(@box_session)[:aws_state],
                                 "running"

    #delete DB version, start over, should find existing instance
    #and assign to database object, making them equal
    remote_id                  = @box.remote_id
    @box.delete
    @box                       = @Box.find_or_create_by_name @Config.box.name, @box_session

    assert_equal                 @box.remote_id, remote_id

    #finally, Box.remotes_by_name.first should return
    #the same as simply remote
    assert_equal                 @Box.remotes_by_name(@Config.box.name, nil, @box_session).first,
                                 @box.remote(@box_session)
  end

  def test_terminate
    #make sure the instance is up and running for latest @box
    @box                       = @Box.find_or_create_by_name @Config.box.name, @box_session
    assert_equal                 @box.remote(@box_session)[:aws_state],
                                 "running"
    @box.terminate               @box_session
    #remotes array should be empty
    @remotes                   = @Box.remotes_by_name @Config.box.name, nil, @box_session
    assert_equal                 @remotes, []
  end
end
