require "test_helper"
class SshTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @github_public        = TestHelper.github_public
    @worker_name          = Mobilize.config.minitest.ec2.worker_name
    @ec2                  = TestHelper.ec2(@worker_name)
    @ec2_session          = Mobilize::Ec2.session
    @ec2.find_or_create_instance(@ec2_session)
    @user                 = TestHelper.user(@ec2)
    @ssh                  = TestHelper.ssh(@ec2)
    @ssh_session          = Mobilize::Ssh.session
    @github_session       = Mobilize::Github.session
    @job                  = TestHelper.job(@user)
    @github_public_task   = TestHelper.task(@job,@github_public,"read",@github_session)
    @ssh_task             = TestHelper.task(@job,@ssh,"run",@ssh_session,
                                            input: "ls path1",
                                            subs: {
                                                    path1: @github_public_task.cache.dir
                                                   }
                                            )
  end

  def test_run
    @github_public.read(@github_public_task)
    @ssh_task.cache.refresh
    @ssh_task.cache.purge
    @ssh.run(@ssh_task)
    assert_in_delta @ssh_task.streams[:stdout].length, 1, 1000
  end
end
