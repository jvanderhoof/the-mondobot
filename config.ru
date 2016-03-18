require 'rubygems'
require 'bundler'

Bundler.require
Dotenv.load

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

require './mondobot'

run Mondobot
