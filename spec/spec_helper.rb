require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'webmock/rspec'

require 'pry'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fluent/test'
require 'fluent/plugin/out_redshift_alternative'

# Disable Test::Unit
module Test::Unit::RunCount; def run(*); end; end

if ENV['COVERAGE']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]

  SimpleCov.start do
    add_filter 'spec'
    add_filter 'pkg'
    add_filter '.bundle'
  end

  Coveralls.wear!
end

if ENV['CODECLIMATE_REPORT']
  WebMock.disable_net_connect!(allow: 'codeclimate.com')
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

path = Pathname.new(Dir.pwd)
Dir[path.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.before(:all) do
    Fluent::Test.setup
  end

  config.order = 'random'
end
