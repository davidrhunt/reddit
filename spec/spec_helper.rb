begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

begin
  require 'ruby-debug'
rescue LoadError
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'reddit'

module RedditSpecHelpers
  def read_fixture(filename)
    fixture = File.dirname(__FILE__) + '/fixtures/' + filename
    File.read(fixture)
  end
end

Spec::Runner.configure do |config|
  config.include(RedditSpecHelpers)
end
