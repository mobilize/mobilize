module Mobilize
  module Logger
    def Logger.trace_header(stack_trace)
      @header               = stack_trace.first.split(Mobilize.root).last
      @response             = "[#{Time.now.utc}]: #{@header}"
      begin
        if                    Mobilize.config.log.level == "info"
          #cut off time and root trace at the beginning
          @header           = @header.split("/").last
          @response         = @header
        end
      rescue
        #leave header as was; config not loaded yet
      end
      #pad the response according to config
      @ljusted_response     = "#{@header}:".ljust(Mobilize.config.log.ljust," ")
      return                  @ljusted_response
    end
    def Logger.info(message,object=nil)
      @caller               = caller(1)
      @log                  = Logger.trace_header(@caller) + message
      puts                    @log
    end
    def Logger.error(message,object=nil)
      @c                    = caller(1)
      @log                  = Logger.trace_header(@caller) + message
      raise                   @log
    end
  end
end
