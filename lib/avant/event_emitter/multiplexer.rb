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

      def subscribe
        philotic = Philotic.connection
        philotic.subscriber.subscribe(SUBSCRIPTION, ack: true) do |metadata, message|
          begin
            stat = {
                'stat'  => message[:attributes]['stat'],
                'count' => message[:attributes]['count'],
                't'     => metadata.attributes[:timestamp],
            }

            Avant::EventEmitter::Emitter.emit!(stat)

            acknowledge(message)

          rescue => e
            reject(message)
            logger.error e.message
          end
        end
        philotic.subscriber.endure
      end
    end
  end
end