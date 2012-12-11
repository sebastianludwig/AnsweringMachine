require 'rubygems'

require 'bundler'
Bundler.require(:default, ENV['RACK_ENV'])

$LOAD_PATH << File.join(File.dirname(__FILE__))
$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
$LOAD_PATH << File.join(File.dirname(__FILE__), 'helper')

require 'answering_machine'

run MockServer