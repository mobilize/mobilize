require "test_helper"
class ClusterTest < MiniTest::Unit::TestCase
  def setup
    Mobilize::Cluster.perform    "terminate"
  end

  def test_spin_up
    Mobilize::Cluster.perform    "install"
    Mobilize::Cluster.perform    "start"

    #wait for workers to rev up
    _resque_web_workers          = Mobilize::Cluster.resque_web_workers
    _workers_per_engine          = Mobilize.config.cluster.engines.workers.count
    _engines                     = Mobilize::Cluster.engines

    _engines.each do |_engine|
      _key                       = "ip-#{ _engine.ip }".pretty_key
      assert_equal                 _resque_web_workers[ _key ],
                                   _workers_per_engine.to_s
    end
    _total_workers               = _workers_per_engine * _engines.length
    assert_equal                   _resque_web_workers[ :all_workers ], _total_workers.to_s

  end

  def teardown
    #Mobilize::Cluster.perform "terminate"
  end
end
