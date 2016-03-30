require 'rubygems'
require 'dotenv'
Dotenv.load

require 'bundler/setup'
Bundler.require(:default)


Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

client = Slack::Web::Client.new
client.auth_test


channel = "#testing-grounds"
client.chat_postMessage(channel: channel, text: '<@U04C98124> Hello World', as_user: true)

#channels = client.channels_list.channels

#puts channels.inspect
