module YAML
  def YAML.load_file_indifferent( _path )
    YAML.load_file( _path ).with_indifferent_access
  end
  def YAML.easy_hash_string( _value )
    if _value.is_between? "/"
       Regexp.new(     _value.between "/" )
    else 
      _value.gsub      ": //", "://"
    end
  end
  def YAML.easy_hash_array( _value )
    _value.map { |_array_value| _array_value.to_s.gsub ": //", "://" }
  end
  def YAML.easy_hashify( _string )
    _hash_string                      = _string.is_between?( '{', '}' ) ? _string : "{#{_string}}"
    _colon_space_string               = _hash_string.gsub( ":", ": " ).gsub( ":  ", ": " )
    YAML.load                           _colon_space_string
  end
  def YAML.easy_hash_load( _string )
    _easy_hash                        = YAML.easy_hashify _string
    _result_hash                      = {}
    _easy_hash.each                  { |_key, _value|
      _stripped_key                   = _key.strip
      if                                _value.class == String or _value.class == Array
        _result_hash[ _stripped_key ] = YAML.send "easy_hash_#{ _value.class.to_s.downcase }", _value
      else
        _result_hash[ _stripped_key ] = _value
      end
                                     }
    _result_hash
  end
end
