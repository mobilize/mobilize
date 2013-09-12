module Mobilize
  module Logger
    def Logger.trace_header(stack_trace)
      return "[#{Time.now.utc}]: #{stack_trace.first.split(Mobilize.root).last}"
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
