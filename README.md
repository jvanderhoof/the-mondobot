# Mondo Slackbot

## Introduction

This is a project to enable external service integration with Slack.

## Installation

This project utilizes Sinatra to receive webhook callbacks.  As such, you'll need Ruby installed on your system to run it locally.

To install, clone this repository locally.  Step into the project and run `bundle` to install all gem dependencies.

To run the project, run: `rackup`.  The project should come up on `http://localhost:9292`.  To verify the project is running, hit the testing page:

`http://localhost:9292/testing`


## Deployment

This project utilizes the Heroku Builder gem for configuration and deployment.  Assuming you have access to the Heroku project, simply run `rake builder:production:deploy` to push your changes after they've been merged into the master branch.


## Configuration

### All Integrations
In order for the Slackbot to send messages to a channel, it needs to be invited to that channel!  Inviting is simple:

```
/invite @therobot
```

### Heroku
Adding Heroku notifications to a channel is a two step process. First, add the Heroku project and Slack channel to the `app_to_channel` method in the `mondobot.rb` class:

```ruby
  def app_to_channel(app)
    {
      'the-mondobot' => '#testing-grounds'
    }
  end
```

The key is the Heroku app name, and the value is the channel (make sure to include the '#').  Commit and deploy your change.  The next step is to create the webhook.  This can be done with the following command:

```bash
heroku addons:create deployhooks:http --url=http://the-mondobot.herokuapp.com/heroku -a the-mondobot
```

### Github

To add PR @mentions to a project, make sure the Github project name and Slack channel is in the `app_to_channel` method. Also, verify that all developers on the project are listed in the `github_user_to_slack_user` method.  If a user has the same handle for Slack and Github, no need to do anything!

Add a webhook to Github.  `Payload URL` should be set to: `http://the-mondobot.herokuapp.com/github`.  Choose `Let me select individual events.`, and check 'Pull Request'.  Then save and verify the webhook was successful.
