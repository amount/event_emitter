require 'philotic/message'
require 'active_support/core_ext/hash'

module Avant
  module EventEmitter
    class Event < Philotic::Message

      PRODUCT    = :avant
      COMPONENT  = :event_emitter
      MESSAGE_TYPE = :'event_emitter.event'

      attr_routable :stat
      attr_payload :count
      attr_payload :value

      def initialize(attributes={})
         attributes.symbolize_keys!
        super

        @philotic_product    = PRODUCT
        @philotic_component  = COMPONENT
        @philotic_message_type = MESSAGE_TYPE

        self.stat  = attributes[:stat]
        self.count = attributes[:count]
        self.value = attributes[:value]
      end

      def philotic_product=(val)
      end

      def philotic_component=(val)
      end

      def philotic_message_type=(val)
      end

    end
  end
end