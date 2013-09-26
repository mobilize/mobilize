require "test_helper"
class SshTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @github_public        = TestHelper.github_public
    @worker_name          = Mobilize.config.minitest.ec2.worker_name
    @ec2                  = TestHelper.ec2(@worker_name)
    @user                 = TestHelper.user(@ec2)
    @ssh                  = TestHelper.ssh(@ec2)
    @github_session       = Github.login
    @job                  = TestHelper.job(@user)
    @github_public_task   = TestHelper.task(@job,@github_public,"read")
    @ssh_task             = TestHelper.task(@job,@ssh,"run",
                                            stdin: "ls path1 path2",
                                            gsubs: {
                                                    path1: @github_public.repo_name,
                                                    path2: @github_private.repo_name
                                                   }
                                            )
  end

end
