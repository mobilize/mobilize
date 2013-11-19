class Object
  def is( &blk )
    self.instance_eval( &blk )
  end
end
