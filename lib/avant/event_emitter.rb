Dir["#{File.dirname(__FILE__)}/#{File.basename(__FILE__, '.rb')}/*.rb"].each {|file| require file }
require 'pathname'
require 'yaml'

# Emits statsd style events to a set of services.
#
module Avant
  module EventEmitter
    def self.root
      ::Pathname.new File.expand_path('../../../', __FILE__)
    end
    def self.philotic_queues
      YAML.load_file(root.join('config', 'philotic_queues.yml'))
    end
  end
end

