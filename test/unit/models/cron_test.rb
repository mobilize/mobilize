require "test_helper"
class CronTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
  end
end
