[![Build Status](https://travis-ci.org/mobilize/mobilize.png?branch=master)](https://travis-ci.org/mobilize/mobilize)

[![Code Climate](https://codeclimate.com/repos/5228cc797e00a4686f016728/badges/1be30681e6c984b33eea/gpa.png)](https://codeclimate.com/repos/5228cc797e00a4686f016728/feed)

# Mobilize

Mobilize allows you to create job schedules in Google Spreadsheets,
which are then used to deploy code from Github to EC2 instances. The
outputs from these scripts can be written to any endpoint, but this API
will prioritize access to RDS, Google Spreadsheets, Google Files, and
S3.

* Mobilize currently allows you to create a cluster of resque workers
running Mobilize through EC2 with a redis connection through
Elasticache. 
*  This will soon support running scheduled code deployments and data
transfers scalably and asynchronously.

## Configuration files

* create a `~/.mobilize` directory
* create a subdirectory `~/.mobilize/config`.
  * copy [mobrc][0] into `~/.mobilize/config/mobrc`.
    * this file contains super secret usernames and passwords for all
      your services.
* create a subdirectory `~/.mobilize/keys`
  * use `ssh-keygen` to create two keypairs called `box.ssh` and `git.ssh`
    * store these keys under `~/.mobilize/keys`
    * you will use these keys to interact with github and ec2.

## Credentials

You'll need to sign up for:
* [AWS](http://aws.amazon.com)
  * Add your access key id and secret access key to `mobrc`
  * [EC2](http://http://aws.amazon.com/ec2)
    * set up a keypair named "mobilize", using the public key `box.ssh.pub`
    * Add inbound TCP access to HTTP (port 80) for the `default` security group. 
  * [Elasticache](http://aws.amazon.com/elasticache/)
    * set up an instance of Redis elasticache in the `default` security group.
    * add the host and port for your Redis box to `mobrc`
    * add your chosen Resque username and password to `mobrc` 
      * this will be set up during installation.
* [Google Drive](http://drive.google.com)
  * add your email and password to `mobrc`
* [Github](http://github.com)
  * add your login (owner name) and password to `mobrc`
    * add your `git.ssh.pub` key to github as a public key.
* [Mongolab](http://mongolab.com)
  * create a database named `mobilize-test`, with your chosen username
    and password.
  * add your host:port, username, and password to `mobrc`

## Installation, Logging, Monitoring

* install RVM and Ruby 1.9.3 with:
  * `\curl -L https://get.rvm.io | bash -s stable --ruby=1.9.3`

* install git with `sudo apt-get install git` or `brew install git`
  depending on your system

* install mobilize with:
  * `git clone https://github.com/mobilize/mobilize.git && cd mobilize && rake install`
  * This will copy default configs to `~/.mobilize/config/config.yml`

* tail application logs with:
  * `mob log tail`

* install your mobilize cluster:
  * `mob cluster install`

* start your mobilize cluster (5 engines with 5 Resque workers each):
  * `mob cluster start`

* monitor your workers (you will need to enter your resque-web username/password)
  * `mob cluster view`

* terminate your mobilize cluster (5 engines with 5 Resque workers each):
  * `mob cluster terminate`

## Console

* launch the Mobilize console with:
  * `mob console`
    * This will load all settings and allow you to browse the test
environment in `pry`.

[0]: http://github.com/mobilize/mobilize/blob/master/samples/mobrc
