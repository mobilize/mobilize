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
  def popen4(_except = nil, _all_streams = nil)
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

       Mobilize::Logger.write _err_str, "FATAL"

    elsif _all_streams == false

      return _out_str

    else

      return {in: _in_str,
              out: _out_str,
              err: _err_str}

    end
  end
  #returns a shortened version of the string with an ellipsis if appropriate
  def ellipsize(_length, _ellipsis = "(...)")
    _str               = self
    _ellipsis          = "" unless _str.length > _length
    return              _str[0.._length-1] + " " + _ellipsis
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
