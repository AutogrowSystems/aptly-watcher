module Aptly
  module Watcher
    class EventDispatcher
      def initialize(aptly)
        @added = []
        @aptly = aptly
      end

      def process(dir, event, component)
        return false unless valid_event?(event)
        
        filepath  = "#{dir}/#{event.name}"

        raise StandardError, "File not found: #{filepath}" unless File.exists? filepath

        @aptly.add(component, filepath)
        @aptly.publish

        @added << event.name
        true
      end

      def valid_event?(event)
        return false if
          ( @added.include? event.name ) or
          ( event.name.nil? or event.name == '' )
        true
      end

    end
  end
end