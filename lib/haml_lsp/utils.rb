# frozen_string_literal: true

module HamlLsp
  Interface = LanguageServer::Protocol::Interface
  Constant = LanguageServer::Protocol::Constant

  # General utility methods
  module Utils
    def self.word_at_position(content, line, character)
      lines = content.to_s.lines
      return nil if line >= lines.size

      target_line = lines[line]
      return nil if character > target_line.length

      # Find word boundaries
      left = character - 1
      right = character

      left -= 1 while left >= 0 && target_line[left] =~ /\w/
      right += 1 while right < target_line.length && target_line[right] =~ /\w/

      target_line[(left + 1)...right]
    end

    def self.line_at_position(content, line)
      lines = content.to_s.lines
      return nil if line >= lines.size

      lines[line]
    end

    # Calculate distance between two file paths based on directory levels
    # @param path1 [String] First path
    # @param path2 [String] Second path
    # @return [Integer] Number of directory levels between paths
    def self.path_distance(path1, path2)
      parts1 = path1.split("/")
      parts2 = path2.split("/")

      common_length = 0
      [parts1.length, parts2.length].min.times do |i|
        break if parts1[i] != parts2[i]

        common_length += 1
      end

      (parts1.length - common_length) + (parts2.length - common_length)
    end

    def self.full_content_range(content)
      line_count = content.lines.size
      last_line_length = content.lines.last&.chomp&.length || 0

      Interface::Range.new(
        start: Interface::Position.new(line: 0, character: 0),
        end: Interface::Position.new(line: line_count, character: last_line_length)
      )
    end
  end
end
