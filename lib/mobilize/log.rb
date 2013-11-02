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
    field :_id,       type: String, default:->{"#{time.to_f.to_s}/#{host}#{path}/#{call}/#{line.to_s}" }

    def Log.write(_message, _level = "INFO")
      _trace                = caller(1)
      _header               = _trace.first.split(Mobilize.root).last
      _call                 = _header.split('`').last[0..-2]
      _line                 = _header.split(':')[-2].to_i
      _path                 = _header.split(':').first
      _host                 = Socket.gethostname
      _revision             = Mobilize.revision
      _log                  = Log.create(level: _level, path:    _path,    line: _line,
                                         call:  _call,  message: _message, host: _host, revision: _revision)
      if _level            == "FATAL"
        raise                 _log.message
      end
    end
    def Log.tail(_conditions = nil, _limit = 10)
      _last_log, _tail_logs  = Log.last, nil
      while 1 == 1
        _query               = Log
        if _conditions
           _query            = _query.where _conditions
        end

        if _tail_logs
              _query         = _query.where :_id.gt => _last_log.id
              _tail_logs     = _query.to_a
        else
              _query         = _query.desc( :_id ).limit( _limit )
              _tail_logs     = _query.to_a.reverse
        end

        _tail_logs.each     { |_tail_log| _tail_log.pp }

        _last_log            = _tail_logs.last || _last_log

        sleep 1
      end
    end

    def pp_level
      _color = case self.level
               when "FATAL"
                 "light_red"
               when "ERROR"
                 "light_yellow"
               when "STAT"
                 "light_white"
               else
                 "light_green"
               end
      _level = self.level.ljust( 5, " " )
      "[#{ _level.send _color}]";
    end

    def pp_time;    "[#{ self.time.strftime "%Y-%m-%d %H:%M:%S" }]";                                        end

    def pp_host;    "[#{ self.host.ellipsize 23 }]";                                                        end

    def pp_path;    " #{ self.path.white }:#{ self.line.to_s.magenta }".ljust( 80, " " ) + " ";             end

    def pp_file;    " #{ self.path.basename.white }:#{ self.line.to_s.magenta }".ljust( 45, " " ) + " ";    end

    def pp_call;    "in #{ self.call.white }: ".ljust( 45, " " ) + " ";                                     end

    def pp_message; self.message.split( 'stderr' ).map { |_text| _text.light_cyan }.join 'stderr'.light_red;end

    def pp(_fields = [:level, :time,  :host, :file, :call, :message])
      _log, _result          = self, ""

      _fields.each { |_field| _result += _log.send "pp_#{ _field.to_s }" }
      puts _result
    end
  end
end
