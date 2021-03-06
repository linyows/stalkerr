# coding: utf-8

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require 'stalkerr'
require 'rspec'
require 'webmock/rspec'
require 'vcr'
require 'awesome_print'

WebMock.disable_net_connect!(allow: 'coveralls.io')

RSpec.configure do |c|
  c.include WebMock::API
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

def fixture_path
  File.expand_path('../fixtures', __FILE__)
end

def fixture(file)
  File.new(fixture_path + '/' + file)
end

def json_response(file)
  {
    :body => fixture(file),
    :headers => {
      :content_type => 'application/json; charset=utf-8'
    }
  }
end

def method_missing(method, *args, &block)
  if method =~ /^a_(get|post|put|delete)$/
    a_request(Regexp.last_match[1].to_sym, *args, &block)
  elsif method =~ /^stub_(get|post|put|delete|head|patch)$/
    stub_request(Regexp.last_match[1].to_sym, *args, &block)
  else
    super
  end
end
