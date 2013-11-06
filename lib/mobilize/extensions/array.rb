class Array
  #processes an array of procs and returns their results
  def thread
    require      'thread/pool'
    _array     = self
    _result    = [ nil ] * _array.length
    _pool      = Thread.pool _array.length

    _array.each_with_index { |_proc, _proc_i|

      _pool.process {

        _result[ _proc_i ]  = begin
                                _proc.call
                              rescue => _exc
                                _exc
                              end
      }
    }
    _pool.shutdown
    _result
  end
  #selects hash members whose attributes all match the query_hash
  def hash_match( _query_hash )
    _array                       = self
    _array.select do              |_member|
      _matches = _query_hash.map{ |_key, _value|
                                   _value.to_a.include? _member[ _key ] }.uniq
      _matches.length == 1 and _matches.first  == true
    end
  end
  def all( _method = nil, &blk )
    _array           = self
    if                 _method
      _map_array     = _array.map{|_member| _member.send _method }
    else
      _map_array     = _array.map( &blk )
    end
    return true unless _map_array.include? false or
                       _map_array.include? nil
  end
  def to_hash_array
    _array           = self
    _hash_array      = []
    _headers         = _array.first.map { |_header| _header.alphanunderscore.to_sym }
    _rows            = _array[ 1..-1 ]

    _rows.each     do |_row|
      _hash_row      = {}

      _row.each_with_index do |_value, _header_i|

        _header              = _headers[ _header_i ]
        _hash_row[ _header ] = _value

      end

      _hash_array << _hash_row
    end

    _hash_array
  end
  #turn 2 column table into hash
  def tuples_to_hash( _has_header = true, _pretty_key = true )
    _array               = _has_header ? self[ 1..-1 ] : self
    _hash                = Hash.new.with_indifferent_access
    _array.each        do |_key, _value|
      _hash_key          = _pretty_key ? _key.pretty_key : _key
      _hash[ _hash_key ] = _value
    end
    _hash
  end
end
