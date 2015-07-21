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

        # create a repo for each component
        @components.each do |repo|
          next if repo_list.include? repo  # avoid raising an error
          output = `aptly repo create #{distrib} #{config} #{component(repo)} #{repo} 2>&1`
          raise StandardError, "Failed to create repo #{repo}\n#{output}" unless $?.success?
          Aptly::Watcher.log :info, "Created repo #{@name}/#{repo}"
        end

        # publish the repos for the first time (empty)
        unless `aptly publish list --raw`.include? @name # avoid raising an error
          output = `aptly publish repo #{config} #{distrib} #{component(:all)} #{@components.join(' ')} 2>&1`
          raise StandardError, "Failed to publish #{@name} for the first time\n#{output}" unless $?.success?
          Aptly::Watcher.log :info, "Published repos #{@components.join('/')} for #{@name}"
        end
      end

      def add(repo, path)
        # TODO: check if the file has already been added
        # TODO: check that the file is a Debian package
        output = `aptly repo add -remove-files=true #{config} #{repo} #{path} 2>&1`
        raise StandardError, "Failed to add #{path} to #{repo}\n#{output}" unless $?.success?
      end

      def publish
        system "aptly publish update #{config} #{@name}"
      end

      private

      def component(repo)
        repo = @components.join(',') if repo == :all
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