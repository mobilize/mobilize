require "test_helper"
class SshTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @github_public        = TestHelper.github_public
    @worker_name          = Mobilize.config.minitest.ec2.worker_name
    @ec2                  = TestHelper.ec2(@worker_name)
    @user                 = TestHelper.user(@ec2)
    @ssh                  = TestHelper.ssh(@ec2)
    @ssh_session          = Mobilize::Ssh.session
    @github_session       = Mobilize::Github.session
    @job                  = TestHelper.job(@user)
    @github_public_task   = TestHelper.task(@job,@github_public,"read",@github_session)
    @ssh_task             = TestHelper.task(@job,@ssh,"run",@ssh_session,
                                            input: "ls path1",
                                            gsubs: {
                                                    path1: @github_public.repo_name,
                                                   }
                                            )
  end

  def test_run
    @job.clear_cache
    @github_public.read(@github_public_task)
    @ssh.run(@ssh_task)
    assert_in_delta @ssh_task.stdout.length, 1, 1000
  end

  def teardown
    @job.purge_cache
  end
end
