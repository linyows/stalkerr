# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stalkerr/version'

Gem::Specification.new do |spec|
  spec.name          = 'stalkerr'
  spec.version       = Stalkerr::VERSION
  spec.authors       = ['linyows']
  spec.email         = ['linyows@gmail.com']
  spec.description   = %q{Stalkerr is IRC Server for stalking :)}
  spec.summary       = %q{Stalkerr is IRC Gateway, inspired by agig and atig.}
  spec.homepage      = 'https://github.com/linyows/stalkerr'
  spec.license       = 'MIT'

  spec.required_ruby_version = Gem::Requirement.new('>= 2.0.0')

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'net-irc', '~> 0.0.9'
  spec.add_dependency 'octokit', '~> 3.4.0'
  spec.add_dependency 'string-irc', '~> 0.3.0'
  spec.add_dependency 'qiita', '~> 0.0.3'
end
