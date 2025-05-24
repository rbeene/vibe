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

  # Dependencies are managed in Gemfile
end