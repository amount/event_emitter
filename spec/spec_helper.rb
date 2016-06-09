$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'support'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'config'))


require 'rubygems'
require 'bundler/setup'
require 'rspec/its'

require 'hosted_graphite'
HostedGraphite.api_key = 'YOUR API KEY'

Bundler.require(:default, :test)

RSpec.configure do |config|
  #Run any specs tagged with focus: true or all specs if none tagged
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  
end
