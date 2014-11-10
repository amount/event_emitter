require 'philotic/event'

module Avant
  module EventEmitter
    class Event < Philotic::Event

      PHILOTIC_PRODUCT = 'avant'.freeze
      PHILOTIC_COMPONENT = 'event_emitter'.freeze
      PHILOTIC_EVENT_TYPE = 'event_emitter.event'.freeze

      attr_routable :stat
      attr_payload :count
      attr_payload :value

      def initialize(attributes={})
        super

        self.philotic_product = PHILOTIC_PRODUCT
        self.philotic_component = PHILOTIC_COMPONENT
        self.philotic_event_type = PHILOTIC_EVENT_TYPE

        self.stat = attributes['stat']
        self.count = attributes['count']
        self.value = attributes['value']
      end

      def philotic_product=(val)
        super PHILOTIC_PRODUCT
      end

      def philotic_component=(val)
        super PHILOTIC_COMPONENT
      end

      def philotic_event_type=(val)
        super PHILOTIC_EVENT_TYPE
      end

    end
  end
end