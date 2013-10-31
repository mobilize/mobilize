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
end
