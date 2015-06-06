require 'active_support/inflector'

Dir["#{__dir__}/#{File.basename(__FILE__, '.rb')}/*.rb"].each { |file| require file }


module Avant
  module EventEmitter
    module Emitter

      extend self

      attr_accessor :logger

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def emitters
        emitter_files = Dir["#{__dir__}/#{File.basename(__FILE__, '.rb')}/*.rb"]
        emitter_files.reject { |f| f.end_with? '/base.rb' }.inject([]) do |classes, emitter_path|
          emitter_path = emitter_path.gsub("#{__dir__}/#{File.basename(__FILE__, '.rb')}", self.name.underscore).gsub('.rb', '')

          emitter_name = emitter_path.split('/').last

          enabled_env_key = "#{emitter_name.upcase}_ENABLED"
          if ENV[enabled_env_key]
            classes << emitter_path.classify.constantize
          else
            logger.info { "Skipping #{emitter_name}, ENV['#{enabled_env_key}'] is not set." }
          end

          classes
        end
      end
    end
  end
end