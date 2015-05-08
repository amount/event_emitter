require 'stathat/json'
require 'awesome_print'
require 'active_support/all'

require 'avant/event_emitter/emitter/base'

module Avant
  module EventEmitter
    module Emitter
      module StatHatEmitter

        include Avant::EventEmitter::Emitter::Base

        extend self

        def emit_stats(stats, sanitize=true)
          stats = stats.map { |stat| sanitize_stat stat } if sanitize

          response = StatHat::Json::Api.post_stats stats

          unless response.valid?
            if response.message == 'json too long'
              batch_size = stats.count/2
              logger.info "#{response.message} splitting into batches of #{batch_size}"
              stats.each_slice(batch_size).each do |stats_chunk|
                emit_stats stats_chunk, false
              end
              logger.info "published #{stats.count} in batches of #{batch_size}"

              return
            end
            raise RuntimeError.new "publishing error #{response.body}. stats: #{stats.count}"
          end
          logger.info "published #{stats.count} stats to StatHat"
        end
      end
    end
  end
end