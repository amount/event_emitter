require 'stathat'
require 'librato/metrics'
require 'logger'

module Avant
  module EventEmitter
    class Emitter

      STATHAT_SCRUBBER_REGEX = Regexp.new('[!?]')
      class << self
        attr_accessor :drivers, :stathat_email, :librato_email, :librato_api_key, :prefix

        def stathat_email
          @stathat_email ||= ENV['AVANT_EVENT_EMITTER_STATHAT_ACCOUNT']
        end

        def librato_email
          @librato_email ||= ENV['AVANT_EVENT_EMITTER_LIBRATO_EMAIL']
        end

        def librato_api_key
          @librato_api_key ||= ENV['AVANT_EVENT_EMITTER_LIBRATO_API_KEY']
        end

        def prefix
          @prefix ||= ENV['AVANT_EVENT_EMITTER_PREFIX']
        end

        def drivers
          @drivers ||= [:stathat]
        end

        def drivers=(drivers)
          @drivers = if drivers.is_a?(Array)
                       drivers.map { |d| parse_driver(d) }
                     else
                       [parse_driver(drivers)]
                     end
        end

        def emit!(opts = {})
          drivers.each { |d| _emit! d, parse_opts(opts) }
        end

        def auth_librato!
          Librato::Metrics.authenticate librato_email, librato_api_key
        end

        protected
        def parse_driver(driver)
          if driver.is_a?(Logger) || driver.is_a?(IO) || driver.is_a?(StringIO)
            driver
          else
            case driver.to_s
              when /stathat/
                StatHat::API
              when /librato/
                auth_librato!
                Librato::Metrics
              when /logger/
                defined?(Rails) && Rails.logger
            end
          end
        end

        def _emit!(driver, payload)
          prefixed_stat = if pfix = payload[:prefix] || prefix
                            [pfix, payload[:stat]] * '.'
                          else
                            payload[:stat]
                          end

          input   = payload[:count] || payload[:value]
          stat, t = payload[:stat], payload[:t]

          if driver == StatHat::API
            account = stathat_email
            if payload[:count]
              driver.ez_post_count(prefixed_stat, account, payload[:count], payload[:iso8601_t])
            else
              driver.ez_post_value(prefixed_stat, account, payload[:value], payload[:iso8601_t])
            end
          elsif driver == Librato::Metrics
            if payload[:count]
              driver.submit({
                                stat => {type: :gauge, value: payload[:count], measure_time: t.to_i, source: prefix}
                            })
            else
              driver.submit({
                                stat => {type: :gauge, value: payload[:value], measure_time: t.to_i, source: prefix}
                            })
            end
          else
            if driver.is_a?(Logger)
              driver.info [prefixed_stat, input, t].join(',')
            else
              puts [prefixed_stat, input, t].join(',')
            end
          end
        end

        def parse_opts(opts)
          opts          = Hash[opts.map { |k, v| [k.to_sym, v] }]
          opts[:prefix] = sanitize opts[:prefix]
          opts[:stat]   = sanitize opts[:stat]

          if ts = opts[:t]
            opts[:t] = if ts.is_a?(Time)
                         ts rescue nil
                       elsif ts.is_a?(Numeric) || ts.is_a?(String) && ts =~ /^(\d)+$/
                         Time.at(ts) rescue nil
                       elsif ts.is_a?(Date)
                         ts.to_time
                       else
                         Time.parse(ts) rescue nil
                       end

            opts[:iso8601_t] = opts[:t].iso8601
          end

          opts
        end

        def sanitize stat
          # Stat hat does not support these characters in emitted stats
          stat.try(:gsub, STATHAT_SCRUBBER_REGEX, '')
        end
      end
    end
  end
end