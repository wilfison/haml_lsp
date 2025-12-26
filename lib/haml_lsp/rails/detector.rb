# frozen_string_literal: true

module HamlLsp
  module Rails
    # Module to detect if a project is a Rails project
    module Detector
      def self.rails_project?(root_uri)
        return false unless root_uri

        root_path = URI.decode_uri_component(root_uri.sub("file://", ""))
        rails_indicator_files = [
          "config/application.rb",
          "Gemfile",
          "config/routes.rb"
        ]

        rails_indicator_files.all? do |relative_path|
          File.exist?(File.join(root_path, relative_path))
        end
      end
    end
  end
end
