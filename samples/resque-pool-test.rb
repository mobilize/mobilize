require 'mobilize'
God.watch do |w|
  w.name = "resque-pool-#{Mobilize.env}"
  w.interval = 30.seconds
  w.env = { 'MOBILIZE_ENV'   => Mobilize.env,
            'RESQUE_ENV'     => Mobilize.env,
            'REDIS_HOST'     => Mobilize.config.redis.host,
            'REDIS_PORT'     => Mobilize.config.redis.port,
            'REDIS_PASSWORD' => Mobilize.config.redis.password,
            'TERM_CHILD'     => 1}
  w.dir = File.expand_path(File.join(File.dirname(__FILE__),'..'))
  w.start = "resque-pool -d -E #{Mobilize.env} " +
            "-o ~/.mobilize/log/resque-pool-#{Mobilize.env}.log " +
            "-e ~/.mobilize/log/resque-pool-#{Mobilize.env}.err " +
            "-p #{Mobilize.config.resque.pid_dir}/resque-pool-#{Mobilize.env}.pid"
  w.start_grace = 10.seconds
 
  # restart if memory gets too high
  w.transition(:up, :restart) do |on|
    on.condition(:memory_usage) do |c|
      c.above = 200.megabytes
      c.times = 2
    end
  end
 
  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end
 
  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
      c.interval = 5.seconds
    end
 
    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
      c.interval = 5.seconds
    end
  end
 
  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_running) do |c|
      c.running = false
    end
  end
end

