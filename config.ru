require 'rubygems'

require 'bundler'
Bundler.require(:default)

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')

require 'mock_server'

run MockServer