require "test_helper"
class GithubTest < MiniTest::Unit::TestCase
  def setup
    @test                      = self
    @Fixture                   = Mobilize::Fixture
    @github_public             = @Fixture::Github.public
    @user                      = @Fixture::User.default
    @crontab                   = @Fixture::Crontab.default  @user
    @cron                      = @Fixture::Cron._once       @crontab,        "github_test"
    @github_private            = @Fixture::Github.private
    @stage                     = @Fixture::Stage.default    @cron,  1,  "read"
    #assign same session to both githubs
    @github_public_task        = @Fixture::Task.default     @stage,  1, @github_public
    @github_private_task       = @Fixture::Task.default     @stage,  2, @github_private
  end

  def test_run
    Mobilize::Log.write                   "starting github test"
    #_start_time                         = Time.now.utc
    Mobilize::Cli.perform                 [ "cron", "enqueue", @cron.id ]
    #monitor logs until expected messages are complete
    #@test.expect _start_time
  end

  def teardown
    #@github_public.delete
    #@github_private.delete
  end
end
