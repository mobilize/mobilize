module Mobilize
  class Ssh < Path
    include Mongoid::Document
    include Mongoid::Timestamps
    field :user_name,        type: String #username for box
    field :private_key_path, type: String
    field :ec2_id,           type: String #needed for id
    field :home_dir,         type: String, default:->{"/home/#{user_name}"}
    field :_id,              type: String, default:->{"ssh/#{ec2_id}/#{user_name}"}
    belongs_to :ec2

    def input(task)
      @task       = task
      @worker     = @task.worker
      @worker     .refresh
      @worker     .purge
      File.open("#{@worker.dir}","w") {|f| f.print(@task.input)}
      Logger.info "wrote input into worker at #{@worker.dir}"
    end

    def Ssh.session
      "session"#placeholder
    end

    def run(task)
      @ssh       = self
      @task      = task
      @ssh       .input(@task)
      #deploy ssh command to cache
      @task      .deploy
      #cd to job dir and execute file from there
      exec_cmd   = "(cd #{@task.cache.parent_dir}/ && sh stdin) > " +
                   "#{@task.cache.parent_dir}/stdout 2> " +
                   "#{@task.cache.parent_dir}/stderr; " +
                   "touch #{@task.cache.parent_dir}/log; " +
                   "echo $? > #{@task.cache.parent_dir}/exit_signal"
      @ssh       .sh(exec_cmd)
      return     true
    end

    def streams(task)
      @ssh                 = self
      @task                = task
      delim                = "MOBILIZE_SSH_RESULT_DELIMITER"
      stream_array         = ["stdin","stdout","stderr","exit_signal","log"]

      result_cmd           = "cd #{@task.cache.parent_dir} && " +
                             "array=(#{stream_array.join(" ")}) " +
                             "&& (for each in \"${array[@]}\"; do :; " +
                             "cat $each; echo #{delim}; done)"

      result_string        = @ssh.sh(result_cmd)[:stdout]
      result_array         = result_string.split(delim).map{|stream| stream.strip}

      return               {stdin:       result_array[0],
                            stdout:      result_array[1],
                            stderr:      result_array[2],
                            exit_signal: result_array[3],
                            log:         result_array[4]}
    end

    def sh(command,except=true)
      @ssh     = self
      ssh_args = {keys: [@ssh.private_key_path],paranoid: false}
      @result  = Net::SSH.send_w_retries("start",@ssh.ec2.dns,@ssh.user_name,ssh_args) do |ssh|
                   ssh.run(command,except)
                 end
      return   @result
    end

    def cp(loc_path, rem_path)
      @ssh     = self
      ssh_args = {keys: [@ssh.private_key_path],paranoid: false}
      @result  = Net::SCP.send_w_retries("start",@ssh.ec2.dns,@ssh.user_name,ssh_args) do |scp|
                   scp.upload!(loc_path,rem_path) do |ch, name, sent, total|
                     Logger.info "#{name}: #{sent}/#{total}"
                   end
                 end
      return   @result
    end
  end
end
