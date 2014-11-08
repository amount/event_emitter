require 'philotic/event'

module Avant
  module EventEmitter
    class Event < Philotic::Event

      PHILOTIC_PRODUCT = 'avant'.freeze
      PHILOTIC_COMPONENT = 'event_emitter'.freeze

      attr_routable :stat
      attr_payload :count

      def initialize(attributes={})
        super

        self.philotic_product = PHILOTIC_PRODUCT
        self.philotic_component = PHILOTIC_COMPONENT

        self.stat = attributes['stat']
        self.count = attributes['count']
      end

      def philotic_product=(val)
        super PHILOTIC_PRODUCT
      end

      def philotic_component=(val)
        super PHILOTIC_COMPONENT
      end

    end
  end
end