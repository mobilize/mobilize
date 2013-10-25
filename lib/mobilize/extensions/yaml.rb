module YAML
  def YAML.load_file_indifferent(_path)
    YAML.load_file(_path).with_indifferent_access
  end
end
