require "test_helper"
class CronTest < MiniTest::Unit::TestCase
  def setup
    @test                               = self
    @Fixture, @Gfile, @Script           = Mobilize::Fixture, Mobilize::Gfile, Mobilize::Script
    @Config                             = Mobilize.config.fixture

    @user                               = @Fixture::User.default
    @crontab                            = @Fixture::Crontab.default  @user
  end

  def test_trigger
    _cron, _parent_cron               = nil, nil
    _class_methods                    = Mobilize::Fixture::Cron.methods false
    _trigger_methods                  = _class_methods.select{|_method| _method.to_s.starts_with? "_" }
    _trigger_methods.each            { |_trigger_method|
      puts _trigger_method
      if _trigger_method.to_s.index "parent"

        _parent_cron.delete          if _parent_cron
        _cron.delete                 if _cron
        _cron, _parent_cron           = Mobilize::Fixture::Cron.send _trigger_method, @crontab

      else

        _cron.delete                 if _cron
        _cron                         = Mobilize::Fixture::Cron.send _trigger_method, @crontab

      end
      assert_equal _cron[ :expected ], _cron.triggered?
    }
  end
end
