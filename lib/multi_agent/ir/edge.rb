# frozen_string_literal: true

require "dry-struct"

module MultiAgent
  module IR
    class Edge < Dry::Struct
      attribute :id, Types::String
      attribute :source, Types::String
      attribute :target, Types::String
      attribute :type, Types::String.enum("data", "control")
      attribute :metadata, Types::Hash.default { {} }
    end
  end
end