require 'logger'
module Mobilize
  module Logger
    def Logger.trace_header(_trace, _level)
      _header               = _trace.first.split(Mobilize.root).last
      _response             = "[#{Time.now.utc}]: #{_header}"
      begin
        if                    Mobilize.config.log.level == "info"
          #cut off time and root trace at the beginning
          _header           = _header.split("/").last
          _response         = _header
        end
      rescue
        #leave header as was; config not loaded yet
      end
      #pad the response according to config or 0 if not loaded yet
      _ljust_length         = begin;Mobilize.config.log.ljust;rescue;0;end
      _ljusted_response     = "[#{_level.ljust(5," ")}] #{_header}:".ljust(_ljust_length, " ")
      _ljusted_response
    end
    def Logger.write(_message, _level = nil)
      _trace, _message      = caller(1), _message
      _level                = _level || "INFO"
      _log                  = Logger.trace_header(_trace, _level) + _message
      _file_path            = File.expand_path "#{Mobilize.log_dir}/#{Mobilize.env}.log"
      _logger               = ::Logger.new _file_path, "daily"
      _logger.info            _log
      if _level == "FATAL"
        raise _log
      else
        puts  _log
      end
    end
  end
end
