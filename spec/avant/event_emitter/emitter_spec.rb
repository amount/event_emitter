require 'spec_helper'
require 'stathat/json'
require 'avant/event_emitter/emitter'

module Avant
  module EventEmitter
    describe Emitter do

      describe '.emitters' do
        it 'should find all emitters' do
          expect(subject.emitters).to eq [Avant::EventEmitter::Emitter::StatHatEmitter]
        end
      end

    end
  end
end