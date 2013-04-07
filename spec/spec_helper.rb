# coding: utf-8

unless ENV['CI']
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec'
  end
end

require 'stalkerr'
require 'rspec'
require 'webmock/rspec'

RSpec.configure do |config|
  config.include WebMock::API
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
