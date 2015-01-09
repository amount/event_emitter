require 'stathat/json'
require 'awesome_print'
require 'active_support/all'

module Avant
  module EventEmitter
    module Emitter
      module Base

        attr_accessor :logger
        
        def logger
          @logger ||= Logger.new(STDOUT)
        end

      end
    end
  end
end