module Aptly
  module Watcher
    class AptlyShim
      def initialize(name, components, config)
        @name       = name       # distribution
        @components = components # repos
        @config     = config

        create
      end

      def create
        repo_list = `aptly repo list --raw`

        @components.each do |repo|
          next if repo_list.include? repo
          output = `aptly repo create #{distrib} #{config} #{component(repo)} #{repo}`
          raise StandardError, "Failed to create repo #{repo}\n#{output}" unless $?.success?
        end

        published_list = `aptly publish list --raw`

        unless published_list.include? @name
          output = `aptly publish repo #{config} #{distrib} #{component(:all)} #{component(:all, ' ')}`
          raise StandardError, "Failed to publish #{@name} for the first time\n#{output}" unless $?.success?
        end
      end

      def add(repo, path)
        # TODO: check if the file has already been added
        # TODO: check that the file is a Debian package
        output = `aptly repo add -remove-files=true #{config} #{repo} #{path} 2>&1`
        raise StandardError, "Failed to add #{path} to #{repo(component)}\n#{output}" unless $?.success?
      end

      def publish
        system "aptly publish update #{config} #{@name}"
      end

      private

      def component(repo, joiner=',')
        repo = @components.join(joiner) if repo == :all
        "-component=#{repo}"
      end

      def distrib
        "-distribution=#{@name}"
      end

      def config
        "-config='#{@config}'"
      end
    end
  end
end