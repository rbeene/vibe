# frozen_string_literal: true

require "json"

module MultiAgent
  module IR
    class Serializer
      def self.save(graph, path)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, graph.to_json)
      end

      def self.load(path)
        Graph.from_json(File.read(path))
      end
    end
  end
end