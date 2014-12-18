# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'avant/event_emitter/version'

Gem::Specification.new do |spec|
  spec.name                  = 'avant-event_emitter'
  spec.version               = Avant::EventEmitter::VERSION
  spec.authors               = ['Nathan Keyes']
  spec.email                 = ['nathan.keyes@avantcredit.com']
  spec.summary               = %q{Avatn Event Emitter}
  spec.description           = %q{publish events to 3rd party services}
  spec.homepage              = ''
  spec.files                 = `git ls-files -z`.split("\x0")
  spec.executables           = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files            = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths         = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'rspec-its', '~> 1.1'

  spec.add_dependency 'philotic', '>= 0.5.0'
  spec.add_dependency 'stathat'
  spec.add_dependency 'librato-metrics'

end
