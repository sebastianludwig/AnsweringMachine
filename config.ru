require 'rubygems'

require 'bundler'
Bundler.require(:default)

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
$LOAD_PATH << File.join(File.dirname(__FILE__), 'helper')

require 'mock_server'

run MockServer