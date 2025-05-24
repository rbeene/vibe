# frozen_string_literal: true

require "dry-struct"

module MultiAgent
  module IR
    class Node < Dry::Struct
      attribute :id, Types::String
      attribute :type, Types::String.enum("agent", "task", "workflow")
      attribute :name, Types::String
      attribute :metadata, Types::Hash.default { {} }
      attribute :inputs, Types::Array.of(Types::String).default { [] }
      attribute :outputs, Types::Array.of(Types::String).default { [] }
    end
  end
end