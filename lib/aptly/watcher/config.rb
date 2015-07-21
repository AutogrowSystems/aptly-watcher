require 'yaml'
require 'json'

module Aptly
  module Watcher
    module Config
      class << self

        def parse(config_file)
          raise ArgumentError, "Config file not found: #{config_file}" unless File.exist?(config_file)
          config = YAML.load_file(config_file)
          valid_config!(config)
          config = parse_tildes(config)
          config[:aptly] = parse_aptly_conf(config[:conf])
          config
        end

        def valid_config!(config)
          raise ArgumentError, "Config file was empty"              unless config
          raise ArgumentError, "Config file missing :pidfile:"      unless config[:pidfile]
          raise ArgumentError, "Config file missing :conf:"         unless config[:conf]
          raise ArgumentError, "Config file missing :log:"          unless config[:log]
          raise ArgumentError, "Config file missing :repos:"        unless config[:repos]
          raise ArgumentError, "Config file missing :distrib:"      unless config[:distrib]
          raise ArgumentError, "Config file missing :incoming_dir:" unless config[:incoming_dir]
        end

        # Parse any tildes into the full home path
        def parse_tildes(config)
          [:pidfile, :conf, :incoming_dir, :log].each do |key|
            config[key].sub! /~/, ENV['HOME']
          end

          config
        end

        # Load the aptly config
        def parse_aptly_conf(conf)
          raise ArgumentError, "Aptly config file does not exist: #{conf}" unless File.exist? conf
          JSON.parse(File.read(conf))
        end

      end
    end
  end
end