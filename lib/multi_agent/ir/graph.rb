# frozen_string_literal: true

require "dry-struct"
require "set"

module MultiAgent
  module IR
    class Graph < Dry::Struct
      attribute :nodes, Types::Array.of(Node)
      attribute :edges, Types::Array.of(Edge)
      attribute :metadata, Types::Hash.default { {} }

      def ready_nodes(completed_node_ids = [])
        completed = Set.new(completed_node_ids)
        
        nodes.select do |node|
          dependencies = edges
            .select { |e| e.target == node.id }
            .map(&:source)
          
          dependencies.all? { |dep| completed.include?(dep) }
        end
      end

      def to_json(*args)
        {
          nodes: nodes.map(&:to_h),
          edges: edges.map(&:to_h),
          metadata: metadata
        }.to_json(*args)
      end

      def self.from_json(json)
        data = JSON.parse(json, symbolize_names: true)
        new(
          nodes: data[:nodes].map { |n| Node.new(n) },
          edges: data[:edges].map { |e| Edge.new(e) },
          metadata: data[:metadata] || {}
        )
      end
    end
  end
end