class Array
  #processes an array of procs and returns their results
  def thread
    require      'thread/pool'
    _array     = self
    _result    = [nil] * _array.length
    _pool      = Thread.pool(_array.length)

    _array.each_with_index { |_proc, _proc_i|

      _pool.process {

        _result[_proc_i]    = _proc.call

      }
    }
    _pool.shutdown
    _result
  end
  #selects hash members whose attributes all match the query_hash
  def hash_match( _query_hash )
    _array                      = self
    _array.select do             |_member|
      _matches = _query_hash.map{|_key, _value|
                                  _value.to_a.include? _member[_key]
                                }.uniq
      _matches.length == 1 and _matches.first  == true
    end
  end
end
