# frozen_string_literal: true

require "test_helper"

module HamlLsp
  module Rails
    class PartialsScannerTest < Minitest::Test
      def test_scan_returns_empty_when_root_uri_is_nil
        assert_empty PartialsScanner.scan(nil)
      end

      def test_scan_returns_empty_when_views_dir_missing
        Dir.mktmpdir do |dir|
          assert_empty PartialsScanner.scan(dir)
        end
      end

      def test_scan_finds_partials
        Dir.mktmpdir do |dir|
          views_path = File.join(dir, "app", "views", "users")
          FileUtils.mkdir_p(views_path)
          File.write(File.join(views_path, "_profile.haml"), "%h1 Profile\n")
          File.write(File.join(views_path, "_sidebar.haml"), "%aside Sidebar\n")

          result = PartialsScanner.scan(dir)

          assert_equal 2, result.size
          names = result.map { |r| r[:name] }.sort

          assert_equal ["users/profile", "users/sidebar"], names
        end
      end

      def test_scan_extracts_locals
        Dir.mktmpdir do |dir|
          views_path = File.join(dir, "app", "views", "shared")
          FileUtils.mkdir_p(views_path)
          File.write(
            File.join(views_path, "_header.haml"),
            "-# locals: (title:, subtitle: nil)\n%h1= title\n"
          )

          result = PartialsScanner.scan(dir)

          assert_equal 1, result.size
          locals = result.first[:locals]

          assert_equal 2, locals.size
          assert_equal "title", locals[0][:name]
          assert locals[0][:required]
          assert_equal "subtitle", locals[1][:name]
          refute locals[1][:required]
        end
      end

      def test_scan_returns_entries_without_distance
        Dir.mktmpdir do |dir|
          views_path = File.join(dir, "app", "views")
          FileUtils.mkdir_p(views_path)
          File.write(File.join(views_path, "_footer.haml"), "%footer\n")

          result = PartialsScanner.scan(dir)

          assert_equal 1, result.size
          entry = result.first

          assert_equal "footer", entry[:name]
          assert entry.key?(:file)
          assert entry.key?(:locals)
          refute entry.key?(:distance)
        end
      end
    end
  end
end
