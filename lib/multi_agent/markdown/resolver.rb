# frozen_string_literal: true

module MultiAgent
  module Markdown
    class Resolver
      def initialize
        @paths = {}
        scan_artifacts
      end

      def resolve(name)
        @paths[name]
      end

      private

      def scan_artifacts
        %w[agents tasks workflows].each do |dir|
          Dir.glob("#{dir}/*.md").each do |path|
            name = File.basename(path, ".md")
            @paths[name] = path
          end
        end
      end
    end
  end
end