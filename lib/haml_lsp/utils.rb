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
  end
end
