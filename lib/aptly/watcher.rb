require 'rb-inotify'
require 'redis'

require "aptly/watcher/version"
require 'aptly/watcher/event_dispatcher'
require 'aptly/watcher/aptly_shim'
require 'aptly/watcher/config'

module Aptly
  module Watcher
    class << self

      def redis
        return nil if @config[:redis_log] == false
        @redis ||= Redis.new
      end

      def logger
        return @logger if @logger

        target = case @config[:log]
        when '-'
          STDOUT
        when false
          '/dev/null'
        else
          @config[:log]
        end

        @logger ||= Logger.new target, 0, 1024000
      end
      
      # sets up the incoming directories
      def setup(config)
        @config = config
        @config[:repos].each do |repo|
          repo_dir = "#{@config[:incoming_dir]}/#{@config[:distrib]}/#{repo}"
          
          # Create the directory if it's not already there
          FileUtils.mkdir_p(repo_dir) unless File.directory?(repo_dir)
        end
      end

      def log(level, message)
        message.chomp.lines.each_with_index do |line, index|  # multi line logging
          line.chomp!
          line = "  #{line}" unless index.zero?
          redis_log(level, line)          if @config[:redis_log] != false
          logger.send(level.to_sym, line) if @config[:log]       != false
        end
      end

      def redis_log(level, message)
        return false if redis.nil?
        timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        msg       = "#{level[0].upcase}, [#{timestamp}] #{level.upcase} -- #{message}"
        redis.lpush(@config[:redis_log], msg)
        redis.ltrim(@config[:redis_log], 0, 99)
      end

      # run the watcher with the given config
      def run(config)
        notifier   = INotify::Notifier.new
        aptly      = Aptly::Watcher::AptlyShim.new(config[:distrib], config[:repos], config[:conf])
        dispatcher = Aptly::Watcher::EventDispatcher.new(aptly)

        # setup a notifier for each repo
        config[:repos].each do |repo|
          repo_dir = "#{config[:incoming_dir]}/#{@config[:distrib]}/#{repo}"
          
          # watch the directory for new files
          notifier.watch(repo_dir, :close_write) do |event|
            begin
              dispatcher.process(repo_dir, event, repo)
              log :info, "Successfully added #{event.name} to #{config[:distrib]}/#{repo}"
              system "chown #{config[:user]}:#{config[:group]} #{config[:aptly]['rootDir']} -R"
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
end