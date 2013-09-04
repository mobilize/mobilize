module YAML
  def YAML.load_file_indifferent(path)
    YAML.load_file(path).with_indifferent_access
  end
end
