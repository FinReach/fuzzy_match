require 'rubygems'
require 'bundler'
Bundler.setup
require 'test/unit'
require 'remote_table'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'loose_tight_dictionary'

class Test::Unit::TestCase
end
