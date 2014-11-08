require 'stathat'
require 'librato/metrics'
require 'logger'

module Avant
  module EventEmitter
    class Emitter
      class << self
        attr_accessor :drivers, :stathat_email, :librato_email, :librato_api_key, :prefix
      end

      def self.configure(&blk)
        yield self
      end

      def self.drivers=(drivers)
        @drivers = if drivers.is_a?(Array)
                     drivers.map { |d| parse_driver(d) }
                   else
                     [parse_driver(drivers)]
                   end
      end

      def self.emit!(opts = {})
        drivers.each { |d| _emit! d, parse_opts(opts) }
      end

      def self.auth_librato!
        Librato::Metrics.authenticate librato_email, librato_api_key
      end

      protected
      def self.parse_driver(driver)
        if driver.is_a?(Logger) || driver.is_a?(IO) || driver.is_a?(StringIO)
          driver
        else
          case driver.to_s
            when /stathat/
              require 'stathat'
              StatHat::API
            when /librato/
              require 'librato/metrics'
              auth_librato!
              Librato::Metrics
            when /logger/
              defined?(Rails) && Rails.logger
          end
        end
      end

      def self._emit!(driver, payload)
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

      def self.parse_opts(opts)
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

      def self.sanitize stat
        # Stat hat does not support these characters in emitted stats
        stat.try(:gsub, Regexp.new('[!?]'), '')
      end

    end
  end
end