require "test_helper"
class ClusterTest < MiniTest::Unit::TestCase
  def setup
    Mobilize::Cluster.perform    "terminate"
  end

  def test_spin_up
    Mobilize::Cluster.perform    "install"
    Mobilize::Cluster.perform    "start"

    _workers_per_engine          = Mobilize.config.cluster.engines.workers.count
    _engines                     = Mobilize::Cluster.engines

    _resque_web_workers          = Mobilize::Cluster.resque_web_workers
    #wait for workers to start
    _attempts                    = 0
    while _resque_web_workers.length < _engines.length and _attempts <= 5
      Mobilize::Logger.write       "waiting for workers on all engines"
      _resque_web_workers        = Mobilize::Cluster.resque_web_workers
      sleep 5
      _attempts                 += 1
    end

    raise "Worker engine start failed" if _resque_web_workers.length <= _engines.length

    _engines.each do |_engine|
      _key                       = "ip-#{ _engine.ip }".pretty_key
      assert_equal                 _resque_web_workers[ _key ],
                                   _workers_per_engine.to_s
    end
    _total_workers               = _workers_per_engine * _engines.length
    assert_equal                   _resque_web_workers[ :all_workers ], _total_workers.to_s

  end

  def teardown
    Mobilize::Cluster.perform "terminate"
  end
end
