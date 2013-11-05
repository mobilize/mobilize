require "test_helper"
class BoxTest < MiniTest::Unit::TestCase
  def setup
    @Box                       = Mobilize::Box
    @box_name                  = "mobilize-box-test"
    @box                       = @Box.find_or_create_by_name @box_name
    @box.terminate
  end

  def test_remote
    #create new instance
    @box                       = @Box.find_or_create_by_name @box_name

    assert_equal                 @box.remote[ :aws_state ], "running"

    #delete DB version, start over, should find existing instance
    #and assign to database object, making them equal
    remote_id                  = @box.remote_id
    @box.delete
    @box                       = @Box.find_or_create_by_name @box_name

    assert_equal                 @box.remote_id, remote_id

    #finally, Box.remotes_by_name.first should return
    #the same as simply remote
    assert_equal                 @Box.remotes_by_name( @box_name, nil ).first,
                                 @box.remote
  end

  def teardown
    @box.terminate
  end
end
