require 'spec_helper'
require 'stathat'
require 'librato/metrics'

module Avant
  module EventEmitter
    describe Emitter do
      # FIXME: Avant::EventEmitter::Emitter.drivers= performs mutation on the supplied drivers, so
      # for now just run the drivers we are testing through the parser.
      def parse_drivers(*drivers)
        drivers.map { |d| Avant::EventEmitter::Emitter.send(:parse_driver, d) }
      end

      let(:ee) { Avant::EventEmitter::Emitter }
      let(:t) { Time.now }

      before do
        drivers = parse_drivers(:stdout)
        allow(Avant::EventEmitter::Emitter).to receive(:drivers).and_return(drivers)
        allow(Avant::EventEmitter::Emitter).to receive(:prefix).and_return('test')
      end

      it 'should emit events to stdout' do
        expect { ee.emit! 'stat' => 'foo.something', 'count' => '1', 't' => t.to_r }
        .to output("test.foo.something,1,#{t}\n").to_stdout
      end

      it 'should strip out any/all of [!?] from events' do
        expect { ee.emit! 'stat' => '?!foo.!?something!?', 'count' => '1', 't' => t.to_r }
        .to output("test.foo.something,1,#{t}\n").to_stdout
      end

      describe 'driver auth' do
        before do
          drivers = parse_drivers(:librato, :stathat)
          allow(Avant::EventEmitter::Emitter).to receive(:drivers).and_return(drivers)
          allow(Avant::EventEmitter::Emitter).to receive(:prefix).and_return('drivers')
        end

        it 'should complain about missing credentials' do
          expect { ee.emit! 'stat' => 'foo.something', 'count' => '1', 't' => t.to_r }
          .to raise_error(Librato::Metrics::CredentialsMissing)
        end
      end

      describe 'multiple drivers' do

        before do
          drivers = parse_drivers(:librato, :stathat)
          allow(Avant::EventEmitter::Emitter).to receive(:drivers).and_return(drivers)
          allow(Avant::EventEmitter::Emitter).to receive(:prefix).and_return('drivers')
          allow(Avant::EventEmitter::Emitter).to receive(:stathat_email).and_return('foo@foo.com')
          allow(Avant::EventEmitter::Emitter).to receive(:librato_email).and_return('foo@foo.com')
          allow(Avant::EventEmitter::Emitter).to receive(:librato_api_key).and_return('some api key')

        end

        it 'should be recognized' do
          expect(ee.drivers).to eq [Librato::Metrics, StatHat::API]
        end

        it 'should allow for multiple services' do
          librato_args = {
              'foo.something' => {
                  type: :gauge, value: '1', measure_time: t.to_i, source: ee.prefix
              }
          }
          expect(Librato::Metrics).to receive(:submit).with(librato_args).and_return(true)

          expect(StatHat::API).to receive(:ez_post_count)
                                  .with('drivers.foo.something', ee.stathat_email, '1', t.iso8601)
                                  .and_return(true)

          ee.emit! 'stat' => 'foo.something', 'count' => '1', 't' => t.to_r
        end

      end

    end
  end
end