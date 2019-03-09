# frozen_string_literal: true
require './lib/hamdown_core/version'

Gem::Specification.new do |spec|
  spec.specification_version = 2 if spec.respond_to? :specification_version=
  spec.required_rubygems_version = Gem::Requirement.new(">= 0") if spec.respond_to? :required_rubygems_version=
  spec.name          = 'hamdown_core'
  spec.version       = HamdownCore::VERSION
  spec.authors       = ['Kohei Suzuki', 'Kopylov Vladislav']
  spec.email         = ['kopylov.vlad@gmail.com']

  spec.summary       = 'Parser of Hamlit template language'
  spec.description   = 'Parser of Hamlit template language'
  spec.homepage      = 'https://github.com/kopylovvlad/hamdown_core'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|benchmark)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency 'benchmark-ips'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'haml'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3.3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'solargraph'
end
