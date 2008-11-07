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
