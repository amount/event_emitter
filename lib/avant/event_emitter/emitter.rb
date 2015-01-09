require 'active_support/inflector'

Dir["#{__dir__}/#{File.basename(__FILE__, '.rb')}/*.rb"].each { |file| require file }


module Avant
  module EventEmitter
    module Emitter

      extend self

      def emitters
        emitter_files = Dir["#{__dir__}/#{File.basename(__FILE__, '.rb')}/*.rb"]
        emitter_files.reject { |f| f.end_with? '/base.rb' }.inject([]) do |classes, w|
          w = w.gsub("#{__dir__}/#{File.basename(__FILE__, '.rb')}", self.name.underscore).gsub('.rb', '')
          classes << w.classify.constantize
          classes
        end
      end
    end
  end
end