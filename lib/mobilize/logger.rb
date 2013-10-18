module Mobilize
  module Logger
    def Logger.trace_header(stack_trace, level)
      @header               = stack_trace.first.split(Mobilize.root).last
      @response             = "[#{Time.now.utc}][#{level}]: #{@header}"
      begin
        if                    Mobilize.config.log.level == "info"
          #cut off time and root trace at the beginning
          @header           = @header.split("/").last
          @response         = @header
        end
      rescue
        #leave header as was; config not loaded yet
      end
      #pad the response according to config or 0 if not loaded yet
      @ljust_length         = begin;Mobilize.config.log.ljust;rescue;0;end
      @ljusted_response     = "#{@header}:".ljust(@ljust_length," ")
      return                  @ljusted_response
    end
    def Logger.write(message, level = nil)
      @trace, @message      = caller(1), message
      @level              ||= "INFO"
      @log                  = Logger.trace_header(@trace,@level) + @message
      @file_path            = File.expand_path "#{Mobilize.log_dir}/#{Mobilize.env}.log"
      @logger               = ::Logger.new @file_path, "daily"
      @logger.info(@log)
      if level == "FATAL"
        raise @log
      else
        puts  @log
      end
    end
  end
end
