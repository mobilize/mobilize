require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'
$dir = File.dirname(File.expand_path(__FILE__))
#set test environment
ENV['MOBILIZE_ENV'] = 'test'
require 'mobilize'
$TESTING = true
module TestHelper
  def TestHelper.load_fixture(rel_path)
    #assume yml, check
    yml_file_path = "#{Mobilize.root}/test/fixtures/#{rel_path}.yml"
    standard_file_path = "#{Mobilize.root}/test/fixtures/#{rel_path}"
    if File.exists?(yml_file_path)
      YAML.load_file(yml_file_path)
    elsif File.exists?(standard_file_path)
      File.read(standard_file_path)
    else
      raise "Could not find #{standard_file_path}"
    end
  end
end
