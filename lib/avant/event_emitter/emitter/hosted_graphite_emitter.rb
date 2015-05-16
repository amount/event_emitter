require 'hosted_graphite'
require 'hosted_graphite/statsd'
require 'awesome_print'
require 'avant/event_emitter/emitter/base'

module Avant
  module EventEmitter
    module Emitter
      module HostedGraphiteEmitter

        HostedGraphite.protocol = :udp

        include Avant::EventEmitter::Emitter::Base

        extend self

        def prefix_stat(stat)
          super(stat)
          stat[:stat] = "events.#{stat[:stat]}"
        end

        def emit_stats(stats, sanitize=true)
          stats = stats.map { |stat| sanitize_stat stat } if sanitize

          stats.each do |stat|

            if stat[:count]
              HostedGraphite.count(stat[:stat], stat[:count])
            else
              HostedGraphite.send_metric(stat[:stat], stat[:value])
            end
          end
          logger.info "published #{stats.count} stats to Hosted Graphite"
        end
      end
    end
  end
end