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

        STATHAT_SCRUBBER_REGEX = Regexp.new('[!?]')

        def prefix
          @prefix ||= ENV['AVANT_EVENT_EMITTER_PREFIX']
        end

        def sanitize stat
          # Stat hat does not support these characters in emitted stats
          stat.try(:gsub, STATHAT_SCRUBBER_REGEX, '')
        end

        def sanitize_stat(stat)
          stat.symbolize_keys!
          sanitize_stat_name(stat)
          sanitize_stat_values(stat)
          prefix_stat(stat)
          set_iso8601_t(stat)

          stat
        end

        def set_iso8601_t(stat)
          if ts = stat[:t]
            stat[:t] = if ts.is_a?(Time)
                         ts rescue nil
                       elsif ts.is_a?(Numeric) || ts.is_a?(String) && ts =~ /^(\d)+$/
                         Time.at(ts) rescue nil
                       elsif ts.is_a?(Date)
                         ts.to_time
                       else
                         Time.parse(ts) rescue nil
                       end

            stat[:iso8601_t] = stat[:t].iso8601
          end
          stat.delete :t
        end

        def sanitize_stat_name(stat)
          stat[:prefix] = sanitize stat[:prefix]
          stat[:stat]   = sanitize stat[:stat]
        end

        def sanitize_stat_values(stat)
          if (stat.has_key? :count)
            stat[:count] = stat[:count].to_i rescue 1
            stat.delete :value
          elsif (stat.has_key? :value)
            stat[:value] = stat[:value].to_f rescue 1

          end
          stat[:prefix] = sanitize stat[:prefix]
          stat[:stat]   = sanitize stat[:stat]
        end

        def prefix_stat(stat)
          stat[:stat] = if pfix = stat.delete(:prefix) || prefix
                          [pfix, stat[:stat]] * '.'
                        else
                          stat[:stat]
                        end
        end

        def emit_stats(stats, sanitize=true)
          stats.map! { |stat| sanitize_stat stat } if sanitize

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