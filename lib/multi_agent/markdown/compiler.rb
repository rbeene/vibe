# frozen_string_literal: true

require "commonmarker"
require "yaml"

module MultiAgent
  module Markdown
    class Compiler
      def initialize(resolver: Resolver.new, validator: Validator.new)
        @resolver = resolver
        @validator = validator
      end

      def compile(markdown_path)
        content = File.read(markdown_path)
        doc = CommonMarker.render_doc(content)
        
        # Extract front matter
        front_matter = extract_front_matter(content)
        
        # Validate front matter
        validation_result = @validator.validate(front_matter, markdown_path)
        raise validation_result[:error] if validation_result[:error]
        
        # Build IR graph
        graph = build_graph(doc, front_matter, markdown_path)
        
        # Save compiled IR
        output_path = compiled_path(markdown_path)
        IR::Serializer.save(graph, output_path)
        
        output_path
      end

      private

      def extract_front_matter(content)
        if content =~ /\A---\s*\n(.*?)\n---\s*\n/m
          YAML.safe_load($1, permitted_classes: [Symbol])
        else
          {}
        end
      end

      def build_graph(doc, front_matter, path)
        nodes = []
        edges = []
        
        # Create main node
        main_node = IR::Node.new(
          id: File.basename(path, ".md"),
          type: determine_type(path),
          name: front_matter["name"] || File.basename(path, ".md"),
          metadata: front_matter
        )
        nodes << main_node
        
        # Parse dependencies from content
        doc.walk do |node|
          if node.type == :text && node.string_content =~ /@(\w+)/
            dep_id = $1
            if @resolver.resolve(dep_id)
              edges << IR::Edge.new(
                id: "#{main_node.id}_to_#{dep_id}",
                source: dep_id,
                target: main_node.id,
                type: "data"
              )
            end
          end
        end
        
        IR::Graph.new(nodes: nodes, edges: edges)
      end

      def determine_type(path)
        case path
        when /agents\//  then "agent"
        when /tasks\//   then "task"
        when /workflows\// then "workflow"
        else "task"
        end
      end

      def compiled_path(source_path)
        relative = source_path.sub(/^(agents|tasks|workflows)\//, "")
        "tmp/ir/#{File.dirname(source_path)}/#{File.basename(relative, ".md")}.json"
      end
    end
  end
end