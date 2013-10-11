require "test_helper"
class GithubTest < MiniTest::Unit::TestCase
  include Mobilize
  def setup
    Mongoid.purge!
    @github_public             = Fixture::Github.public
    @worker_name               = Mobilize.config.fixture.ec2.worker_name
    @ec2                       = Fixture::Ec2.default(@worker_name)
    @ec2.find_or_create_instance Ec2.session
    @ssh                       = Fixture::Ssh.default(@ec2)
    @user                      = Fixture::User.default(@ec2)
    @github_private            = Fixture::Github.private
    @job                       = Fixture::Job.default(@user)
    #assign same session to both githubs
    @github_session            = Github.session
    @github_public_task        = Fixture::Task.default(@job,@github_public,"read",@github_session)
    @github_private_task       = Fixture::Task.default(@job,@github_private,"read",@github_session)
  end

  def test_read
    @github_public.read      @github_public_task
    worker_status_cmd      = "cd #{@github_public_task.worker.dir} && git status"
    assert_in_delta          worker_status_cmd.popen4.length, 1, 1000

    cache_status_cmd       = "cd #{@github_public_task.cache.dir} && sudo apt-get install -y git; git status"
    assert_in_delta          @ssh.sh(cache_status_cmd)[:stdout].length, 1, 2000

    if @github_private
      @github_private.read   @github_private_task
      worker_status_cmd    = "cd #{@github_private_task.worker.dir} && git status"
      assert_in_delta        worker_status_cmd.popen4.length, 1, 1000

      cache_status_cmd     = "cd #{@github_private_task.cache.dir} && sudo apt-get install -y git; git status"
      assert_in_delta        @ssh.sh(cache_status_cmd)[:stdout].length, 1, 2000
    end
  end
end
