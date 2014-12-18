require 'avant/event_emitter/emitter'
require 'philotic'
require 'logger'

module Avant
  module EventEmitter
    module Multiplexer
      extend self

      attr_accessor :logger

      SUBSCRIPTION = 'event_emitter_events'

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def emitter
        Avant::EventEmitter::Emitter
      end

      def emit!(*args)
        emitter.emit! *args
      end

      def subscribe
        philotic = Philotic.connection
        philotic.subscriber.subscribe(SUBSCRIPTION, ack: true) do |metadata, message|
          begin
            stat = {
                'stat'  => message[:attributes]['stat'],
                'count' => message[:attributes]['count'],
                't'     => metadata.attributes[:timestamp],
            }

            emit!(stat)

            philotic.subscriber.acknowledge(message)

          rescue => e
            philotic.subscriber.reject(message)
            logger.error e.message
          end
        end
        philotic.subscriber.endure
      end
    end
  end
end