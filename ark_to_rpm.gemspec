# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ark_to_rpm/version'

Gem::Specification.new do |spec|
  spec.name          = 'ark_to_rpm'
  spec.version       = ArkToRpm::VERSION
  spec.authors       = ['Tom Duckering']
  spec.email         = ['tom.duckering@gmail.com']
  spec.description   = %q{A tool to convert archives to installable RPMs}
  spec.summary       = %q{A tool to convert archives to installable RPMs}
  spec.homepage      = 'https://github.com/tomduckering/ark-to-rpm'
  spec.license       = 'Apache 2.0'

  spec.files         = `git ls-files`.split($/)
  spec.files         += ['lib/ark_to_rpm/version.rb']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'

  spec.add_dependency 'fpm'
  spec.add_dependency 'trollop'
end
