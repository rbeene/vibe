# frozen_string_literal: true

require "zeitwerk"
require "semantic_logger"

module MultiAgent
  class << self
    def loader
      @loader ||= Zeitwerk::Loader.for_gem.tap do |loader|
        loader.push_dir(File.expand_path("../", __FILE__))
        loader.inflector.inflect(
          "cli" => "CLI",
          "ir" => "IR"
        )
      end
    end

    def config
      @config ||= load_config
    end

    def logger
      @logger ||= SemanticLogger[self]
    end

    private

    def load_config
      require "yaml"
      require "dry-validation"
      
      config_file = File.expand_path("../../config/project.yaml", __FILE__)
      raw_config = YAML.load_file(config_file)
      
      contract = ConfigContract.new
      result = contract.call(raw_config)
      
      if result.failure?
        raise "Config validation failed: #{result.errors.to_h}"
      end
      
      result.to_h
    end
  end

  class ConfigContract < Dry::Validation::Contract
    params do
      required(:default_runtime).filled(:string)
      required(:default_model).filled(:string)
      required(:log_level).filled(:string)
      required(:concurrency).filled(:integer)
      required(:telemetry_opt_in).filled(:bool)
      required(:openai_api_key_env).filled(:string)
    end
  end
end

MultiAgent.loader.setup
SemanticLogger.default_level = MultiAgent.config[:log_level].to_sym
SemanticLogger.add_appender(io: $stdout, formatter: :json)