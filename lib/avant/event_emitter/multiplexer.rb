require 'avant/event_emitter/emitter'
require 'philotic'

module Avant
  module EventEmitter
    module Multiplexer
      extend self

      SUBSCRIPTION = 'event_emitter_events'

      def emitter
        Avant::EventEmitter::Emitter
      end

      def emit!(*args)
        emitter.emit! *args
      end

      def subscribe
        Philotic::Subscriber.subscribe(SUBSCRIPTION) do |metadata, message|
          stat = {
              'stat' => message[:attributes]['stat'],
              'count' => message[:attributes]['count'],
              't' => metadata.attributes[:timestamp],

          }

          emit!(stat)
        end
        while true
          sleep 1
        end

      end

    end
  end
end