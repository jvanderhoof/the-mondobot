require 'rubygems'
require 'bundler'

Bundler.require
Dotenv.load

require './mondobot'

run Mondobot
