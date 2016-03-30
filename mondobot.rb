class Mondobot < Sinatra::Base
  post '/heroku' do
    log(params)
    heroku_message(params)
    halt 200
  end

  post '/github' do
    #log(request.body.read)
    github_webhook(request.body.read)
    halt 200
  end

  get '/testing' do
    'testing: 1, 2, 3, .....'
  end

  private

  def log(msg)
    @log ||= Logger.new(STDOUT)
    @log.info(msg)
  end

  def client
    @client ||= Slack::Web::Client.new
    @client.auth_test
    @client
  end

  def app_to_channel(app)
    log("app_to_channel: #{app}")
    {
      'the-mondobot' => '#testing-grounds',
      'foxinsight-dev' => '#mjff',
      'foxinsight-staging' => '#mjff',
      'pcrt-web-1781' => '#mjff',
      'pcrt-web' => '#mjff',
      'foxinsight-clinical-trial' => '#mjff',
      'foxinsight-clinical-trial-dev' => '#mjff',
      'foxinsight-clinical-trial-stg' => '#mjff',
      'fox-insight-ppmi' => '#mjff',
      'fi-survey-builder-dev' => '#mjff',
      'fi-survey-builder-stg' => '#mjff',
      'survey-builder' => '#mjff',
      'comcast-simon-dev' => '#comcast-simon',
      'comcast-simon-qa' => '#comcast-simon',
      'comcast-simon-stg' => '#comcast-simon',
      'comcast-simon-test' => '#comcast-simon',
      'Comcast_SDW' => '#comcast-simon',
      'comcast-tn-reservation-dev' => '#comcast-tn-res',
      'comcast-tn-reservation' => '#comcast-tn-res'
    }[app]
  end

  # translate github handle to slack user. If they are the same, no need to add :)
  def github_user_to_slack_user(user)
    log("user: #{user}")
    {
      'Jasmine-Feldmann' => 'jasminefeldmann',
      'jmyers0022' => 'jake',
      'mhfen' => 'fender',
      'mrjman' => 'jesse',
      'subsociety' => 'jonmck',
      'Roballen' => 'roballen',
      'asymptotik' => 'rick',
      'sellestad' => 'stephen'
    }[user] || user
  end

  def slack_user_id(slack_name)
    client.users_info(user: "@#{slack_name}").user.id
  end

  def post_message(channel, message)
    log "posting to: #{channel}"
    client.chat_postMessage(
      channel: channel,
      text: message,
      as_user: true
    )
  end

  def message_to_slack(project_name, message)
    app_to_channel(project_name).split(',').each do |channel|
      post_message(channel, message)
    end
  end

  def github_webhook(webhook)
    msg = JSON.parse(webhook)
    if msg.key?('pull_request') && msg['action'] =~ /opened/
      github_pr_message(msg)
    elsif msg.key?('comment')
      github_pr_comment(msg)
    end
  end

  def github_pr_comment(msg)

  end

  def github_pr_message(msg)
    log msg.keys.inspect
    users = msg['pull_request']['body'].scan(/@([\w\d]+)/).flatten.map do |user|
      github_user_to_slack_user(user)
    end
    callout = users.empty? ? '<!here>' : user_callout(users)
    slack_msg = "#{callout} - PR Review Requested: #{msg['pull_request']['html_url']}"
    message_to_slack(msg['repository']['name'], slack_msg)
  end

  def user_callout(users)
    [*users].map { |user| "<@#{slack_user_id(user)}>" }.join(', ')
  end

  def heroku_message(msg_hsh)
    app = msg_hsh['app']
    message = <<-EOF
    <!here> *#{app}* was deployed with the following changes:
    ```
    #{msg_hsh['git_log']}
    ```
    EOF
    message_to_slack(app, message)
  end
end
