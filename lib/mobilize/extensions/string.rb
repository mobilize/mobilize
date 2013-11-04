require "fileutils"
class String
  def to_a
    return [self]
  end
  def oputs
    STDOUT.puts self
  end
  def eputs
    STDERR.puts self
  end
  def opp
    pp self
  end
  def to_md5
    Digest::MD5.hexdigest self
  end
  #fires system command with full visibility into stdout and stderr
  #default returns stdout only
  #with option to return all streams in hash
  def popen4( _except = nil, _all_streams = nil )
    _except               = true unless _except == false
    _all_streams        ||= false
    _in_str               = self
    _out_str, _err_str    = []

    _status               = Open4.popen4(_in_str) do |_pid, _stdin, _stdout, _stderr|
                              _out_str = _stdout.read
                              _err_str = _stderr.read
                            end

    _exit_status          = _status.exitstatus

    if _exit_status != 0 and
       _except      == true

       Mobilize::Log.write    _err_str, "FATAL"

    elsif _all_streams == false

      return _out_str.strip

    else

      return { in:  _in_str.strip,
               out: _out_str.strip,
               err: _err_str.strip }

    end
  end
  def dirname
    File.dirname self
  end
  def basename
    File.basename self
  end
  def expand_path
    File.expand_path self
  end
  def write( _string )
    File.write self, _string
  end
  def exists?
    File.exists? self
  end
  def cp( _target )
    FileUtils.cp self, _target
  end
  def mkdir_p
    FileUtils.mkdir_p self
  end
  def chmod( _code )
    FileUtils.chmod _code, self
  end
  def rm_r
    FileUtils.rm_r self, force: true
  end
  def is_between?( _start_marker, _end_marker = _start_marker )
    self[0] == _start_marker and self[-1] == _end_marker and self.length >= 2
  end
  def between( _start_marker, _end_marker = _start_marker, _end_marker_last = false )
    if _end_marker_last == false
      #returns string between 2 markers (from stack overflow)
      self[ /#{ Regexp.escape( _start_marker ) }(.*?)#{ Regexp.escape( _end_marker ) }/m, 1 ]
    else
      _start_marker_index = self.index  _start_marker
      _end_marker_index   = self.rindex _end_marker

      self[ self.index( _start_marker_index+1 )..( _end_marker_index-1 )]
    end
  end
  #returns a shortened version of the string with an ellipsis if appropriate
  def ellipsize( _length, _ellipsis = " (...)" )
    _str               = self
    _ellipsis          = "" unless _str.length > _length
    return              _str[0.._length-1] + _ellipsis
  end
  def is_integer?
    self == self.to_i.to_s
  end
  def escape_regex
    _str         = self
    _new_str     = _str.clone
    _char_string = "[\/^$. |?*+()"
    _char_array  = _char_string.chars.to_a
    _char_array.each do |_c|
    _new_str.gsub! _c,"\\#{c}"
    end
    return        _new_str
  end
  #makes everything alphanumeric
  #except spaces, slashes, and underscores
  #which are made into underscores
  def alphanunderscore
    _str          = self
    _alphanum_str = _str.gsub(/[^A-Za-z0-9_\.@ \/]/,"")
    _under_str    = _alphanum_str.gsub(/[ \/\.@]/,"_")
    return         _under_str
  end
end
