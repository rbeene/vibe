# frozen_string_literal: true

require "yaml"

module MultiAgent
  module Plugin
    class Loader
      attr_reader :plugins

      def initialize
        @plugins = {}
        @logger = SemanticLogger[self.class]
        load_all
      end

      def load_all
        Dir.glob("plugins/*/manifest.yml").each do |manifest_path|
          load_plugin(manifest_path)
        end
      end

      def get(name)
        @plugins[name]
      end

      def list
        @plugins.values
      end

      private

      def load_plugin(manifest_path)
        manifest = YAML.load_file(manifest_path)
        name = manifest["name"]
        
        # Load plugin Ruby file
        plugin_dir = File.dirname(manifest_path)
        plugin_file = File.join(plugin_dir, "#{name}.rb")
        
        if File.exist?(plugin_file)
          require_relative "../../../#{plugin_file}"
        end
        
        plugin = {
          name: name,
          version: manifest["version"],
          description: manifest["description"],
          tools: manifest["tools"] || [],
          path: plugin_dir
        }
        
        @plugins[name] = plugin
        @logger.info("Loaded plugin", name: name, version: manifest["version"])
        
      rescue => e
        @logger.error("Failed to load plugin", 
                      manifest: manifest_path, 
                      error: e.message)
      end
    end
  end
end