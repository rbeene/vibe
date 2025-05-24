# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "multi_agent"
  spec.version       = "0.1.0"
  spec.authors       = ["Your Name"]
  spec.email         = ["your.email@example.com"]

  spec.summary       = "Multi-agent orchestration framework"
  spec.description   = "A framework for building and orchestrating multi-agent AI systems"
  spec.homepage      = "https://github.com/yourusername/multi_agent"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir        = "bin"
  spec.executables   = ["mag"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_runtime_dependency "zeitwerk",         "~> 2.6"
  spec.add_runtime_dependency "commonmarker",     "~> 0.23"
  spec.add_runtime_dependency "dry-validation",   "~> 1.10"
  spec.add_runtime_dependency "dry-struct",       "~> 1.6"
  spec.add_runtime_dependency "dry-types",        "~> 1.7"
  spec.add_runtime_dependency "json-schema",      "~> 4.1"
  spec.add_runtime_dependency "dry-cli",          "~> 1.0"
  spec.add_runtime_dependency "faraday",          "~> 2.9"
  spec.add_runtime_dependency "async",            "~> 2.10"
  spec.add_runtime_dependency "fugit",            "~> 1.5"
  spec.add_runtime_dependency "semantic_logger",  "~> 4.15"

  # Development dependencies
  spec.add_development_dependency "rspec",           "~> 3.5.0"
  spec.add_development_dependency "webmock",         "~> 3.23"
  spec.add_development_dependency "timecop",         "~> 0.9"
  spec.add_development_dependency "climate_control", "~> 1.2"
end