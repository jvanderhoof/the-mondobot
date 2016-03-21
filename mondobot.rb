class Mondobot < Sinatra::Base
  post '/heroku' do
    log(params)
    heroku_message(params)
    halt 200
  end

  get '/testing' do
    'testing: 1, 2, 3, .....'
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
      'the-mondobot' => '#testing-grounds',
      'foxinsight-dev' => '#mjff',
      'foxinsight-staging' => '#mjff',
      'pcrt-web-1781' => '#mjff',
      'foxinsight-clinical-trial' => '#mjff',
      'foxinsight-clinical-trial-dev' => '#mjff',
      'foxinsight-clinical-trial-stg' => '#mjff',
      'fi-survey-builder-dev' => '#mjff',
      'fi-survey-builder-stg' => '#mjff'
    }[app]
  end

  def slack_message(channel, message)
    client.chat_postMessage(
      channel: channel,
      text: message,
      as_user: true
    )
  end

  def heroku_message(msg_hsh)
    app = msg_hsh['app']
    message = <<-EOF
    <!here> *#{app}* was deployed with the following changes:
    `#{msg_hsh['git_log']}`
    EOF
    app_to_channel(app).split(',').each do |channel|
      slack_message(channel, message)
    end
  end
end
