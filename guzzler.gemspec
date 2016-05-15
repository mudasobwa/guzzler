# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'guzzler/version'

Gem::Specification.new do |spec|
  spec.name          = 'guzzler'
  spec.version       = Guzzler::VERSION
  spec.authors       = ['Aleksei Matiushkin']
  spec.email         = ['aleksei.matiushkin@kantox.com']

  spec.summary       = 'Remote source crawler (twitter, facebook, html, etc.)'
  spec.description   = 'The simple gem that crawls remote sources for text analysis.'
  spec.homepage      = 'http://rocket-science.ru'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.' unless spec.respond_to?(:metadata)
  # spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'awesome_print', '~> 1.6'

  spec.add_dependency 'hashie', '~> 3'
  spec.add_dependency 'twitter', '~> 5.16'
  spec.add_dependency 'mongo', '~> 2'
end
