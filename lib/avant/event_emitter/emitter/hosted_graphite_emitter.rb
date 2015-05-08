require 'hosted_graphite'
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
            metric = stat[:count] || stat[:value]
            HostedGraphite.send_metric(stat[:stat], metric)

          end
          logger.info "published #{stats.count} stats to Hosted Graphite"
        end
      end
    end
  end
end