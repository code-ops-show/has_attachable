# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'has_attachable/version'

Gem::Specification.new do |spec|
  spec.name          = "has_attachable"
  spec.version       = HasAttachable::VERSION
  spec.authors       = ["Zack Siri"]
  spec.email         = ["zack@artellectual.com"]
  spec.description   = %q{gem for managing async uploading to S3 and background processing with sidekiq}
  spec.summary       = %q{for managing async uploading}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
