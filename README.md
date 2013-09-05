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

### Private Git Repo Access

In order to test private git repo access, you will need to:
1) create a private repo in github
2) create an ssh keypair and add the public one as a deploy key to the
project;
3) define environment variables:
```
  export MOB_TEST_PRIVATE_GIT_PATH_OWNER=<private repo owner>
  export MOB_TEST_PRIVATE_GIT_PATH_REPO=<private repo name>
  export MOB_TEST_PRIVATE_GIT_PATH_BRANCH=<private repo branch>
  export MOB_TEST_PRIVATE_GIT_PATH_FILE=<private repo file>
  export MOB_TEST_PRIVATE_SSH_KEY_PATH=<path to ssh private key for public deploy key>
```
