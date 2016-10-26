# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'delayed_after_commit/version'

Gem::Specification.new do |spec|
  spec.name          = "delayed_after_commit"
  spec.version       = DelayedAfterCommit::VERSION
  spec.authors       = ["Simon Rentzke"]
  spec.email         = ["simon@rentzke.com"]

  spec.summary       = %q{delayed after commit}
  spec.description   = %q{defer your after commit callbacks to sidekiq}
  spec.homepage      = "https://github.com/intellum/delayed_after_commit"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", '>= 4.2.0'
  spec.add_development_dependency "sidekiq", "> 4.1"
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "byebug", '>= 0'
  spec.add_development_dependency "rspec", '>= 0'
  spec.add_development_dependency "sqlite3", '>= 0'
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "appraisal"
end
