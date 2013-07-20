# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bones/rpc/version'

Gem::Specification.new do |spec|
  spec.name          = "bones-rpc"
  spec.version       = Bones::RPC::VERSION
  spec.authors       = ["Andrew Bennett"]
  spec.email         = ["andrew@delorum.com"]
  spec.description   = %q{TODO: Write a gem description}
  spec.summary       = %q{TODO: Write a gem summary}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "celluloid"
  spec.add_dependency "celluloid-io"
  spec.add_dependency "erlang-etf"
  spec.add_dependency "msgpack"
  spec.add_dependency "optionable"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
