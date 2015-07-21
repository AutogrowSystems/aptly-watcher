require 'rb-inotify'
require 'redis'

require "aptly/watcher/version"
require 'aptly/watcher/event_dispatcher'
require 'aptly/watcher/aptly_shim'
require 'aptly/watcher/config'

module Aptly
  module Watcher

    def redis
      @redis ||= Redis.new
    end

    def logger
      return @logger if @logger
      target = (@config[:log] == '-') ? STDOUT : @config[:log]
      @logger ||= Logger.new target, 0, 1024000
    end
    
    # sets up the incoming directories
    def setup(config)
      config[:repos].each do |repo|
        repo_dir = "#{config[:incoming_dir]}/#{repo}"
        
        # Create the directory if it's not already there
        FileUtils.mkdir_p(repo_dir) unless File.directory?(repo_dir)
      end
    end

    # log into redis so we can pick it up in the DMS
    def log(level, message)
      timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      msg       = "#{level[0].upcase}, [#{timestamp}] #{level.upcase} -- #{message}"
      redis.lpush("aptly:watcher:log", msg)
      redis.ltrim("aptly:watcher:log", 0, 99)
      logger.send(level.to_sym, message)
    end

    # run the watcher with the given config
    def run(config)
      notifier   = INotify::Notifier.new
      aptly      = Aptly::Watcher::AptlyShim.new(config[:distrib], config[:repos], config[:conf])
      dispatcher = Aptly::Watcher::EventDispatcher.new(aptly)

      # setup a notifier for each repo
      config[:repos].each do |repo|
        repo_dir = "#{config[:incoming_dir]}/#{repo}"
        
        # watch the directory for new files
        notifier.watch(repo_dir, :close_write) do |event|
          begin
            dispatcher.process(repo_dir, event, repo)
            log :info, "Successfully added #{event.name} to #{repo}"
            system "chown #{config[:user]}:#{config[:user]} #{config[:aptly]['rootDir']} -R"
          rescue StandardError => e
            e.message.lines.each {|line| log :error, line.chomp }
          end
        end
      end

      # start the notifier
      notifier.run
    end

  end
end
