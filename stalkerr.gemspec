require File.expand_path('../lib/stalkerr/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['linyows']
  gem.email         = ['linyows@gmail.com']
  gem.description   = %q{Stalkerr is IRC Server for stalking :)}
  gem.summary       = %q{Stalkerr is IRC Gateway, inspired by agig and atig.}
  gem.homepage      = 'https://github.com/linyows/stalkerr'

  gem.required_ruby_version = Gem::Requirement.new(">= 1.9.3")

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = 'stalkerr'
  gem.require_paths = ['lib']
  gem.version       = Stalkerr::VERSION

  gem.add_dependency 'net-irc', ['>= 0.0.9']
  gem.add_dependency 'json', ['>= 1.7.7']
  gem.add_dependency 'octokit', ['>= 0.0.9']
  gem.add_dependency 'string-irc', ['>= 0.3.0']
  gem.add_dependency 'qiita', ['>= 0.0.3']

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'rspec'
end
