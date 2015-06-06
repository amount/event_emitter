require 'spec_helper'
require 'stathat/json'
require 'avant/event_emitter/emitter'

module Avant
  module EventEmitter
    describe Emitter do

      describe '.emitters' do
        it 'should find all emitters' do
          ENV['HOSTED_GRAPHITE_EMITTER_ENABLED'] = '1'
          ENV['STATHAT_EMITTER_ENABLED'] = '1'
          expect(subject.emitters).to include(Avant::EventEmitter::Emitter::StatHatEmitter, Avant::EventEmitter::Emitter::HostedGraphiteEmitter)
        end
      end
    end
  end
end