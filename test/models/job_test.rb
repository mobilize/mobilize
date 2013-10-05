require "test_helper"
class JobTest < MiniTest::Unit::TestCase
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
    @github_public_task   = TestHelper.task(@job,@github_public,"read",@github_session, order: 0)
    @ssh_task             = TestHelper.task(@job,@ssh,"run",@ssh_session,
                                            input: "ls path1",
                                            subs: {
                                                    path1: @github_public_task.cache.dir
                                                   },
                                            order: 1
                                            )
  end

  def test_perform
    TestHelper.resque
    #enqueue job and watch steps
    Job.perform(@job.id)
  end

end
