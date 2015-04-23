# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tdameritrade_api/version'

Gem::Specification.new do |spec|
  spec.name          = "tdameritrade_api"
  spec.version       = TDAmeritradeApi::VERSION
  spec.authors       = ["Winston Kotzan"]
  spec.email         = ["wak@wakproductions.com"]
  spec.summary       = %q{This is a simple gem for connecting to the TD Ameritrade API}
  spec.description   = %q{Only contains limited functionality}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = [`git ls-files`.split($/)] + Dir["lib/**/*"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.2"
  spec.add_dependency "bundler", "~> 1.5"
  spec.add_dependency "rake"
  spec.add_dependency "bindata", "~> 1.8"
  spec.add_dependency "httparty", "~> 0.13"
  spec.add_dependency "activesupport", "~> 4.0.0"
  spec.add_dependency "nokogiri", "~> 1.6"
end
