Dir["#{File.dirname(__FILE__)}/#{File.basename(__FILE__, '.rb')}/*.rb"].each {|file| require file }

# Emits statsd style events to a set of services.
#
module Avant
  module EventEmitter

  end
end

