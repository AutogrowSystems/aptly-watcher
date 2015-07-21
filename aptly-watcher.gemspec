# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aptly/watcher/version'

Gem::Specification.new do |spec|
  spec.name          = "aptly-watcher"
  spec.version       = Aptly::Watcher::VERSION
  spec.authors       = ["Robert McLeod"]
  spec.email         = ["robert@autogrow.com"]
  spec.summary       = %q{Watches folders and adds them to their relative aptly repository}
  spec.description   = %q{Configures Aptly in a application centric manner, and watches a set of folders for incoming Debian packages.}
  spec.homepage      = "https://github.com/AutogrowSystems/aptly-watcher"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "slop", "~> 3.0"
  spec.add_dependency "rb-inotify"
  spec.add_dependency "redis"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
