require 'avant/event_emitter/emitter'
require 'philotic/singleton'
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

      def build_stat(metadata, message)
        {
            'stat'  => message[:attributes]['stat'],
            't'     => metadata[:timestamp],
        }.tap do |stat|
          stat[:value] = message[:attributes]['value'] if message[:attributes]['value']
          stat[:count] = message[:attributes]['count'] if message[:attributes]['count']
        end
      end

      def stat_queue
        @stat_queue ||= Queue.new
      end

      def message_queue
        @message_queue ||= Queue.new
      end

      def last_publish_attempted_at
        @last_publish_attempted_at ||= Time.now.to_i
      end

      def publish_wait_time
        @publish_wait_time ||= ENV['EVENT_EMITTER_PUBLISH_WAIT_TIME'] || 10.seconds
      end

      def subscribe

        Philotic.subscribe(SUBSCRIPTION, ack: true) do |message, metadata, queue|

          Avant::EventEmitter::Multiplexer.message_queue << message
          Avant::EventEmitter::Multiplexer.stat_queue << Avant::EventEmitter::Multiplexer.build_stat(metadata, message)

        end
        Avant::EventEmitter::Multiplexer.start_drain_queue_thread
        Philotic.endure
      end

      def start_drain_queue_thread
        Thread.new do
          loop do
            drain_stat_queue
            sleep 1
          end
        end.abort_on_exception = true
      end

      def drain_stat_queue
        queued_count = stat_queue.size
        if queued_count >= Philotic.config.prefetch_count || time_since_last_publish_attempt >= publish_wait_time
          emit_stats(queued_count)
        end
      end

      def emit_stats(queued_count)
        stats = []
        queued_count.times { stats << @stat_queue.pop }

        if stats.length > 0
          Avant::EventEmitter::Emitter.emitters.each do |emitter|
            emitter.emit_stats(stats)
          end

          while !message_queue.empty?
            message = message_queue.pop
          end
          Philotic.acknowledge(message, true) if message
        end

        @last_publish_attempted_at = Time.now.to_i

      rescue => e
        logger.error e.message
        queued_count.times { Philotic.reject message_queue.pop }
      ensure
        stat_queue.clear
        message_queue.clear
        @last_publish_attempted_at = nil
      end

      def time_since_last_publish_attempt
        Time.now.to_i - last_publish_attempted_at
      end
    end
  end
end