class Object
  #abbreviate instance_eval
  def ie(&blk)
    obj = self
    obj.instance_eval(&blk)
  end
end
