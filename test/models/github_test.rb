require "test_helper"
class GithubTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    Mobilize::Job.purge!
    @Fixture                   = Mobilize::Fixture
    @github_public             = @Fixture::Github.public
    @worker_name               = Mobilize.config.fixture.ec2.worker_name
    @ec2                       = @Fixture::Ec2.default      @worker_name
    @ec2.find_or_create_instance Mobilize::Ec2.session
    @user                      = @Fixture::User.default
    @github_private            = @Fixture::Github.private
    @job                       = @Fixture::Job.default      @user, @ec2
    @stage                     = @Fixture::Stage.default    @job,  1,  "read"
    #assign same session to both githubs
    @github_session            = Mobilize::Github.session
    @github_public_task        = @Fixture::Task.default     @stage,  @github_public,  @github_session
    @github_private_task       = @Fixture::Task.default     @stage,  @github_private, @github_session
  end

  def test_read
    @github_public.send      @stage.call, @github_public_task
    @status_cmd            = "cd #{@github_public_task.dir} && git status"
    assert_in_delta          @status_cmd.popen4.length, 1, 1000

    if @github_private
      @github_private.send   @stage.call, @github_private_task
      @status_cmd          = "cd #{@github_private_task.dir} && git status"
      assert_in_delta        @status_cmd.popen4.length, 1, 1000
    end
  end
end
