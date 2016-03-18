class Mondobot < Sinatra::Base
  post '/heroku' do
    log(params)
    heroku_message(params)
    halt 200
  end

  get '/testing' do
    "testing: 1,2,3....."
  end

  private
  def log(msg)
    @log ||= Logger.new(STDOUT)
    @log.error(msg)
  end

  def client
    @client ||= Slack::Web::Client.new
    @client.auth_test
    @client
  end

  def app_to_channel(app)
    {
      'the-mondobot' => 'testing-grounds'
    }[app]
  end

  def heroku_message(msg_hsh)
    app = msg_hsh["app"]
    channel = "##{app_to_channel(app)}"
    message = <<-EOF
    <!here> *#{app}* was deployed with the following changes:
    `#{msg_hsh['git_log']}`
    EOF
    client.chat_postMessage(channel: channel, text: message, as_user: true)
  end

end
