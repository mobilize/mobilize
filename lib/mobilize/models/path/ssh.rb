module Mobilize
  class Ssh < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :user_name, type: String #username for box
    field :key_path, type: String #path to private key
    belongs_to :ec2
    
    def cache(task)
      return task.job.cache
    end

    def create_cache(task)
      @ssh = self
      @task = task
      #clear out and regenerate server folder
      @ssh.sh("mkdir -p #{@ssh.cache(@task)}")
      Logger.info("Created cache for #{@task.id}")
      return true
    end

    def purge_cache(task)
      @ssh = self
      @task = task
      @ssh.sh("sudo rm -rf #{@ssh.cache(@task)}*")
      Logger.info("Purged cache for #{@task.id}")
    end

    def read_stdin(task)
      @task = self
      File.open("#{@task.cache}/stdin","w") {|f| f.print(@task.stdin)}
      Logger.info("Read stdin into cache for #{@task.id}")
    end

    #gsubs keys in files with the replacement value given
    def gsub!(task)
      @ssh = self
      @task = task
      @task.gsubs.each do |k,v|
        @string1 = Regexp.escape(k.to_s) # escape any special characters
        @string2 = Regexp.escape(v.to_s)
        replace_cmd = "cd #{@task.cache} && (find . -type f \\( ! -path '*/.*' \\) | xargs sed -ie 's/#{@string1}/#{@string2}/g')"
        replace_cmd.popen4(true)
        Logger.info("Replaced #{@string1} with #{@string2} for #{@task.id}")
      end
    end

    def Ssh.session

    end

    def pack_cache(task)
      @ssh = self
      @task = task
      "cd #{@task.cache}/.. && tar -zcvf #{@task.job.name}.tar.gz #{@task.job.name}".popen4(true)
      Logger.info("Packed cache for #{@task.id}")
    end

    def unpack_cache(task)
      @ssh = self
      @task = task
      cache_parent = @ssh.cache.split("/")[0..-2].join("/")
      @ssh.sh("cd #{cache_parent} && tar -zxvf #{@task.job.name}.tar.gz")
      Logger.info("Unpacked cache for #{@task.id}")
    end

    def deploy(task)
      @ssh = self
      @task = task
      Logger.info("Starting deploy for #{@task.id}")
      @ssh.read_stdin(@task)
      @ssh.gsub!(@task)
      @ssh.pack_cache(@task)
      @ssh.cp("#{@task.job.cache}.tar.gz","#{@ssh.cache}.tar.gz")
      Logger.info("Deployed #{@task.id} to cache")
      @ssh.unpack_cache(@task)
      return true
    end

    def run(task)
      @ssh = self
      @task = task
      @ssh.clear_cache(@task)
      #job worker directory to server
      @ssh.deploy(@task)
      @ssh.purge_cache(@task)
      begin
        exec_cmd = "(cd #{@ssh.cache(@task)} && sh stdin) > " +
                   "#{@ssh.cache(@task)}/stdout 2> " +
                   "#{@ssh.cache(@task)}/stderr"
        @ssh.sh(exec_cmd)
        Logger.info("Completed task #{@task.id}")
      rescue
        Logger.error("Failed task #{@task.id} with #{@task.stderr}")
      end
      return true    
    end
   
    def sh(command,except=true)
      @ssh = self
      ssh_args = {keys: @ssh.key_path,paranoid: false}
      @result = Net::SSH.send_w_retries("start",@ssh.ec2.dns,@ssh.user_name,ssh_args) do |ssh|
        ssh.run(command,except)
      end
      return @result
    end

    def cp(loc_path, rem_path)
      @ssh = self
      ssh_args = {keys: @ssh.key_path,paranoid: false}
      @result = Net::SCP.send_w_retries("start",@ssh.ec2.dns,@ssh.user_name,ssh_args) do |scp|
        scp.upload!(loc_path,rem_path) do |ch, name, sent, total|
          Logger.info("#{name}: #{sent}/#{total}")
        end
      end
      return @result
    end
  end
end
