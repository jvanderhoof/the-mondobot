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

