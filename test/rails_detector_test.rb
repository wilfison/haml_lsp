# frozen_string_literal: true

require "test_helper"

module HamlLsp
  module Rails
    class DetectorTest < Minitest::Test
      def test_rails_project_returns_false_for_nil
        refute HamlLsp::Rails::Detector.rails_project?(nil)
      end

      def test_rails_project_returns_false_for_non_rails_project
        Dir.mktmpdir do |dir|
          refute HamlLsp::Rails::Detector.rails_project?(dir)
        end
      end

      def test_rails_project_returns_true_for_rails_project
        Dir.mktmpdir do |dir|
          # Create Rails indicator files
          FileUtils.mkdir_p(File.join(dir, "config"))
          File.write(File.join(dir, "config", "application.rb"), "")
          File.write(File.join(dir, "Gemfile"), "")
          File.write(File.join(dir, "config", "routes.rb"), "")

          assert HamlLsp::Rails::Detector.rails_project?(dir)
        end
      end

      def test_rails_project_returns_false_when_missing_some_files
        Dir.mktmpdir do |dir|
          # Create only some of the Rails indicator files
          FileUtils.mkdir_p(File.join(dir, "config"))
          File.write(File.join(dir, "Gemfile"), "")

          refute HamlLsp::Rails::Detector.rails_project?(dir)
        end
      end
    end
  end
end
