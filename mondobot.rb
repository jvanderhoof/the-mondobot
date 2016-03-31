class Mondobot < Sinatra::Base
  post '/heroku' do
    heroku_message(params)
    halt 200
  end

  post '/github' do
    github_webhook(JSON.parse(request.body.read))
    halt 200
  end

  post '/jira' do
    jira_webhook(JSON.parse(request.body.read))
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

  def project_key_to_channel(project)
    log "project: #{project}"
    {
      'FI' => '#mjff',
      'QE' => '#mjff'
    }[project]
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
  def github_user_to_slack_email(user)
    log("github_user_to_slack_email: #{user}")
    {
      'cprater' => 'cprater@mondorobot.com',
      'lostatseajoshua' => 'joshua@mondorobot.com',
      'jmyers0022' => 'jake@mondorobot.com',
      'mrjman' => 'jesse@mondorobot.com',
      'jvanderhoof' => 'jason@mondorobot.com',
      'mhfen' => 'mfender@mondorobot.com',
      'Jasmine-Feldmann' => 'jasmine@mondorobot.com',
      'subsociety' => 'jon@mondorobot.com',
      'Roballen' => 'rob@mondorobot.com',
      'mondo-todd' => 'todd@mondorobot.com',
      'sellestad' => 'steve@mondorobot.com',
      'justinhillsjohnson' => 'justin@mondorobot.com',
      'asymptotik' => 'rick@mondorobot.com',
      'bgeerdes' => 'bruce@mondorobot.com',
      'geoffreytice' => 'geoff@mondorobot.com',
      'gwieronski' => 'garrett@mondorobot.com'
    }[user] || user
  end

  def slack_user_id(slack_email)
    log "slack_user_id: #{slack_email}"
    @users ||= {}.tap do |hsh|
      client.users_list['members'].each do |user|
        hsh[user['profile']['email']] = user['id']
      end
    end
    @users[slack_email]
  end

  def post_message(channel, message)
    log "posting to: #{channel}"
    client.chat_postMessage(
      channel: channel,
      text: message,
      as_user: true
    )
  end

  def message_to_slack(project_name, message, converter = :app_to_channel)
    #app_to_channel(project_name)
    send(converter, project_name).split(',').each do |channel|
      post_message(channel, message)
    end
  end

  def github_webhook(msg)
    if msg.key?('pull_request') && msg['action'] =~ /opened/
      github_pr_message(msg)
    elsif msg.key?('comment') && msg.key?('issue') && msg['action'] =~ /created/
      github_pr_comment(msg)
    elsif msg.key?('comment')
      github_pr_feedback(msg)
    end
  end

  def github_pr_feedback(msg)
    target_user = user_callout(github_user_to_slack_email(msg['pull_request']['user']['login']))
    slack_msg = "#{target_user} - Feedback on your PR: #{msg['pull_request']['html_url']}"
    message_to_slack(msg['repository']['name'], slack_msg)
  end

  def github_pr_comment(msg)
    return unless msg['comment']['body'] =~ /@([\w\d]+)/
    github_pr_notification(
      msg['comment']['body'],
      msg['issue']['html_url'],
      msg['repository']['name']
    )
  end

  def github_pr_message(msg)
    github_pr_notification(
      msg['pull_request']['body'],
      msg['pull_request']['html_url'],
      msg['repository']['name']
    )
  end

  def github_pr_notification(user_body, pr_link, repo_name)
    user_callout = github_user_callout_to_slack_callout(user_body)
    slack_msg = "#{user_callout} - PR Review Requested: #{pr_link}"
    message_to_slack(repo_name, slack_msg)
  end

  def github_user_callout_to_slack_callout(message_body)
    users = message_body.scan(/@([\w\d]+)/).flatten.map do |user|
      github_user_to_slack_email(user)
    end
    users.empty? ? '<!here>' : user_callout(users)
  end

  def user_callout(users)
    [*users].compact.map { |user| "<@#{slack_user_id(user)}>" }.join(', ')
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

  def jira_webhook(msg)
    case msg['issue_event_type_name']
    when 'issue_assigned'
      jira_issue_assigned(msg['issue'])
    when 'issue_commented'
      jira_issue_commented(msg['issue'])
    end
  end

  def jira_ticket_url(key)
    "https://mondorobot.atlassian.net/browse/#{key}"
  end

  def jira_issue_commented(issue)
    assigned_user = issue['fields']['assignee']['emailAddress']
    return if assigned_user.empty?
    key = issue['key']
    comment = issue['fields']['comment']['comments'].last['body']
    slack_message = "#{user_callout(assigned_user)} - Jira Comment: #{comment} (#{jira_ticket_url(key)})"
    message_to_slack(issue['fields']['project']['key'], slack_message, :project_key_to_channel)
  end

  def jira_issue_assigned(issue)
    assigned_user = issue['fields']['assignee']['emailAddress']
    key = issue['key']
    slack_message = "#{user_callout(assigned_user)} - You were assigned: #{jira_ticket_url(key)}"
    message_to_slack(issue['fields']['project']['key'], slack_message, :project_key_to_channel)
  end
end
