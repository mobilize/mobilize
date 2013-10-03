module Mobilize
  module Logger
    def Logger.trace_header(stack_trace)
      header = stack_trace.first.split(Mobilize.root).last
      begin
        if Mobilize.config.log.level == "info"
          #cut off the extra stuff at the beginning
          header = header.split("/").last
        end
      rescue
        #leave header as was; config not loaded yet
      end
      return "[#{Time.now.utc}]: #{header}}"
    end
    def Logger.info(message,object=nil)
      c = caller(1)
      puts "#{Logger.trace_header(c)}:   #{message}"
    end
    def Logger.error(message,object=nil)
      c = caller(1)
      raise "#{Logger.trace_header(c)}:   #{message}"
    end
  end
end
