# Aptly::Watcher

Configures Aptly in a application centric manner, and watches a set of folders for incoming Debian packages.

The idea is that you setup a user on a server and push packages over SSH to the folder relating to your repo using password-less certificate based login.

**Please note:** this does not publish repositories in the manner recommended by the Aptly developers, which is to publish immutable snapshots rather 
than repositories themselves.  However, personally I found this method convoluted and too sluggish for the fast release cycles I'm used to.  It seems such
a method would be perfect for serving mirrors however.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aptly-watcher'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aptly-watcher

## Usage

First you need to create a config file as such (we parse tildes to `ENV['HOME']`):

```yaml
---
:distrib:      myapp                  # the distribution (or the name of your app)
:repos:                               # the repos to create and publish
  - stable
  - testing
:log:          ~/watcher.log          # use '-' for STDOUT, false to disable
:redis_log:    aptly:watcher:log      # the redis list to log into, set as false to disable
:conf:         ~/aptly.conf           # the location of the aptly conf file
:pidfile:      ~/aptly-watcher.pid    # the location of the aptly-watcher pidfile
:incoming_dir: ~/incoming             # the base incoming directory
:user:         aptly                  # the user to own the aptly directory after adding/publishing
:group:        aptly                  # the group to own the aptly directory after adding/publishing
```

Then you can run the watcher with the config file:

    $ aptly-watcher -c config.yml

This will:

* create the repositories (if they don't exist)
* publish the repository for the first time
* create the folders to watch (if they don't exist)
  * `~/incoming/stable`
  * `~/incoming/testing`
* start watching for files added to the folders

Every time a file is added to one of the watched folders:

* the file is added to the relative repository (i.e. `~/incoming/stable` goes to stable)
* the repository is published again

You will then be able to access your repos via apt like so:

```
deb http://debian.example.com/ myapp stable testing # OR
#deb http://debian.example.com/ myapp stable        # OR
#deb http://debian.example.com/ myapp testing
```

Files added to the folders will immediately be available in the repository.

## Contributing

1. Fork it ( https://github.com/AutogrowSystems/aptly-watcher/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
