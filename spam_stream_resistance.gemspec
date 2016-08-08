# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spam_stream_resistance/version'

Gem::Specification.new do |spec|
  spec.name          = "spam_stream_resistance"
  spec.version       = SpamStreamResistance::VERSION
  spec.authors       = ["Alexey Kondratenko"]
  spec.email         = ["ialexey.kondratenko@gmail.com"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.summary       = 'This library could be used as a spam filter or(and) script manager and could create the black or white lists'
  spec.description   = <<-EOS 
    You can use this library as a spam filter.
    You can add your own filter(scripts) and execute them. (You have to use a key as the first parameter when executing the filter)
    You can create a black or white list with or without time expiration (lifetime) of this list
    You can use a script manager
  EOS
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
