require 'stathat/json'
require 'awesome_print'
require 'active_support/all'

module Avant
  module EventEmitter
    module Emitter
      module Base

        SCRUBBER_REGEX = Regexp.new('[!?]')

        attr_accessor :logger

        def logger
          @logger ||= Logger.new(STDOUT)
        end

        def prefix
          @prefix ||= ENV['AVANT_EVENT_EMITTER_PREFIX']
        end

        def sanitize stat
          # Stat hat does not support these characters in emitted stats
          stat.try(:gsub, SCRUBBER_REGEX, '')
        end

        def sanitize_stat(stat)
          stat = stat.dup
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

      end
    end
  end
end