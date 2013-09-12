module Mobilize
  module Logger
    #stubbing this out for info and error levels
    def Logger.info(message,object=nil)
      c = caller(1)
      trace_header = c.first.split(Mobilize.root).last
      puts "#{trace_header}:   #{message}"
    end
    def Logger.error(message,object=nil)
      c = caller(1)
      trace_header = c.first.split(Mobilize.root).last
      raise "#{trace_header}:   #{message}"
    end
  end
end
