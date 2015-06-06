require 'avant/event_emitter/emitter'
require 'philotic/consumer'
require 'logger'

module Avant
  module EventEmitter
    class Multiplexer < Philotic::Consumer
      attr_accessor :logger

      subscribe_to ENV['EVENT_EMITTER_QUEUE_NAME']

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def build_stat(message)
        {
            'stat' => message.stat,
            'count' => message.count,
            'value' => message.value,
            't'    => message.timestamp,
        }
      end

      def stat_queue
        @stat_queue ||= Queue.new
      end

      def message_queue
        @message_queue ||= Queue.new
      end

      def last_publish_attempted_at
        @last_publish_attempted_at ||= Time.now.to_f
      end

      def publish_wait_time
        @publish_wait_time ||= ENV['EVENT_EMITTER_PUBLISH_WAIT_TIME'] || 0.seconds
      end

      def consume(message)
        message_queue << message
        stat_queue << build_stat(message)
      end

      def subscribe
        super
        start_drain_queue_thread
      end

      def start_drain_queue_thread
        Thread.new do
          loop do
            drain_stat_queue
          end
        end.abort_on_exception = true
      end

      def drain_stat_queue
        queued_count = stat_queue.size
        if queued_count >= Philotic.config.prefetch_count || time_since_last_publish_attempt >= publish_wait_time
          emit_stats(queued_count)
          Thread.pass
        end
      end

      def emit_stats(queued_count)
        stats = []
        messages = []
        queued_count.times do
          stats << @stat_queue.pop
          messages << @message_queue.pop
        end

        if stats.length > 0
          Avant::EventEmitter::Emitter.emitters.each do |emitter|
            emitter.emit_stats(stats)
          end

          acknowledge(messages.last, true) if messages.count > 0
          logger.info "Acked #{messages.count} messages."
        end

        @last_publish_attempted_at = Time.now.to_f

      rescue => e
        logger.error "#{e.message}."
        messages.each { |message| reject message }
      ensure
        @last_publish_attempted_at = nil
      end

      def time_since_last_publish_attempt
        Time.now.to_f - last_publish_attempted_at
      end
    end
  end
end