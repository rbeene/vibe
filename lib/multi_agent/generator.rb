# frozen_string_literal: true

require "erb"
require "fileutils"

module MultiAgent
  class Generator
    TEMPLATE_DIR = File.expand_path("../../templates", __FILE__)

    def generate(type, name)
      template_file = File.join(TEMPLATE_DIR, "#{type}.md.erb")
      
      unless File.exist?(template_file)
        # Special handling for plugin
        if type == "plugin"
          return generate_plugin(name)
        end
        raise "Unknown template type: #{type}"
      end

      output_dir = case type
                   when "agent" then "agents"
                   when "task" then "tasks"
                   when "workflow" then "workflows"
                   when "job" then "jobs"
                   when "eval" then "eval"
                   else raise "Unknown type: #{type}"
                   end

      output_file = case type
                    when "eval" then "#{name}_scorecard.md"
                    else "#{name}.md"
                    end

      output_path = File.join(output_dir, output_file)
      
      FileUtils.mkdir_p(output_dir)
      
      # Render template
      @name = name
      template = ERB.new(File.read(template_file))
      content = template.result(binding)
      
      File.write(output_path, content)
      output_path
    end

    private

    def generate_plugin(name)
      plugin_dir = File.join("plugins", name)
      FileUtils.mkdir_p(plugin_dir)

      # Generate manifest
      @name = name
      manifest_template = File.join(TEMPLATE_DIR, "plugin_manifest.yml.erb")
      manifest_content = ERB.new(File.read(manifest_template)).result(binding)
      File.write(File.join(plugin_dir, "manifest.yml"), manifest_content)

      # Generate plugin file
      plugin_template = File.join(TEMPLATE_DIR, "plugin.rb.erb")
      plugin_content = ERB.new(File.read(plugin_template)).result(binding)
      File.write(File.join(plugin_dir, "#{name}.rb"), plugin_content)

      plugin_dir
    end
  end
end