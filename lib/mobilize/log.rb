module Mobilize
  class Log
    include Mongoid::Document
    field :level,     type: String, default:->{ "INFO" }
    field :time,      type: Time,   default:->{ Time.now.utc }
    field :path,      type: String
    field :line,      type: Fixnum
    field :call,      type: String
    field :message,   type: String
    field :revision,  type: String
    field :host,      type: String
    field :_id,       type: String, default:->{"#{time.to_f.to_s}/#{host}/#{path}/#{call}/#{line.to_s}" }

    def Log.write(_message, _level = "INFO")
      _trace                = caller(1)
      _header               = _trace.first.split(Mobilize.root).last
      _call                 = _header.split('`').last[0..-2]
      _line                 = _header.split(":")[-2].to_i
      _path                 = _header.split(":").first
      _host                 = Socket.gethostname
      _revision             = Mobilize.revision
      _log                  = Log.create(level: _level, path:    _path,    line: _line,
                                         call:  _call,  message: _message, host: _host, revision: _revision)
      if _level            == "FATAL"
        raise                 _log.message
      end
    end
    def Log.tail(_fields = [:level, :time,  :file, :call, :message])
      _last_log, _tail_logs  = Log.last, nil
      while 1 == 1
        _tail_logs           = if _tail_logs

                                 Log.where(:_id.gt => _last_log.id)

                               else

                                 Log.desc(:_id).limit(10)

                               end.order_by(:_id.asc)

        _tail_logs.each     { |_tail_log| _tail_log.pp _fields }

        _last_log            = _tail_logs.last || _last_log

        sleep 1
      end
    end
    def pp(_fields = [:level, :time,  :path, :call, :message])
      _log, _result          = self, ""
      _fields.each  do     |_field|
                      if    _field  == :level
                            _result += "[#{ _log.level}] ".ljust(5, " ")
                      elsif _field  == :time
                            _result += "[#{ _log.time.strftime "%Y-%m-%d %H:%M:%S" }] "
                      elsif _field  == :path
                            _result += "#{_log.path}:#{_log.line.to_s}".ljust(40, " ") + " "
                      elsif _field  == :file
                            _result += "#{File.basename _log.path}:#{_log.line.to_s}".ljust(20, " ") + " "
                      elsif _field  == :call
                            _result += "in '#{_log.call}'; ".ljust(30, " ") + " "
                      elsif _field  == :message
                            _result += _log.message
                      end
                    end
      puts _result
    end
  end
end
