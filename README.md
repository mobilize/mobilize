[![Build Status](https://travis-ci.org/mobilize/mobilize.png?branch=master)](https://travis-ci.org/mobilize/mobilize)

[![Code Climate](https://codeclimate.com/repos/5228cc797e00a4686f016728/badges/1be30681e6c984b33eea/gpa.png)](https://codeclimate.com/repos/5228cc797e00a4686f016728/feed)

# Mobilize

Mobilize allows you to create job schedules in Google Spreadsheets,
which are then used to deploy code from Github to EC2 instances. The
outputs from these scripts can be written to any endpoint, but this API
will prioritize access to RDS, Google Spreadsheets, Google Files, and
S3.

### Configuration Directory

* Mobilize stores its crucial components under ~/.mobilize, with its
configuration files under ~/.mobilize/config

### Environment Variables and Key Files

* Mobilize needs to know some credentials from your system in order to
install and operate itself. They are listed below.


## Installation

### Initial Configuration

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


