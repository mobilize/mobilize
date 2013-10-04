module Mobilize
  module Logger
    def Logger.trace_header(stack_trace)
      header       = stack_trace.first.split(Mobilize.root).last
      response     = "[#{Time.now.utc}]: #{header}"
      begin
        if Mobilize.config.log.level == "info"
          #cut off time and root trace at the beginning
          header   = header.split("/").last
          response = header
        end
      rescue
        #leave header as was; config not loaded yet
      end
      return       header
    end
    def Logger.info(message,object=nil)
      c     = caller(1)
      puts  "#{Logger.trace_header(c)}:   #{message}"
    end
    def Logger.error(message,object=nil)
      c     = caller(1)
      raise "#{Logger.trace_header(c)}:   #{message}"
    end
  end
end
