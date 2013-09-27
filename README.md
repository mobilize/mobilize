[![Build Status](https://travis-ci.org/mobilize/mobilize.png?branch=master)](https://travis-ci.org/mobilize/mobilize)

[![Code Climate](https://codeclimate.com/repos/5228cc797e00a4686f016728/badges/1be30681e6c984b33eea/gpa.png)](https://codeclimate.com/repos/5228cc797e00a4686f016728/feed)

# Mobilize

Mobilize allows you to create job schedules in Google Spreadsheets,
which are then used to deploy code from Github to EC2 instances and run
EMR jobs, RDS queries, or run generic SSH scripts.

## Deployment

Please refer to the
[mobilize-deploy](https://github.com/mobilize/mobilize-deploy) repo for
deployment and configuration instructions.

## Usage

### Console

Mobilize uses Pry for the console. Install the gem and run 
`mob console <env>`
to get a prompt in the Mobilize context. 
Default `<env>` is development.

## Testing

1. clone the repo
2. install the m gem
3. test each test under "test" individually

### Private Git Repo Access


