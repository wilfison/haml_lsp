# frozen_string_literal: true

module HamlLsp
  module Completion
    # Module to provide HAML attribute completions
    module Attributes
      ATTRIBUTE_REGEXP = /%[\w:\-_.#]+([{(])/

      # Common HTML attributes
      GLOBAL_ATTRIBUTES = %w[
        id class style title
        data- aria-
        accesskey contenteditable dir draggable hidden lang spellcheck tabindex translate
      ].freeze

      # Attributes by tag type
      TAG_SPECIFIC_ATTRIBUTES = {
        "a" => %w[href target rel download hreflang type],
        "img" => %w[src alt width height loading],
        "input" => %w[type name value placeholder disabled required readonly checked autocomplete min max step pattern],
        "form" => %w[action method enctype target autocomplete novalidate],
        "button" => %w[type name value disabled formaction formmethod],
        "select" => %w[name multiple size disabled required],
        "textarea" => %w[name rows cols placeholder disabled required readonly maxlength],
        "label" => %w[for],
        "link" => %w[rel href type media],
        "meta" => %w[name content charset http-equiv],
        "script" => %w[src type async defer crossorigin integrity],
        "style" => %w[type media],
        "iframe" => %w[src width height name sandbox allow],
        "video" => %w[src controls autoplay loop muted poster width height],
        "audio" => %w[src controls autoplay loop muted],
        "table" => %w[border cellpadding cellspacing],
        "td" => %w[colspan rowspan headers],
        "th" => %w[colspan rowspan scope headers]
      }.freeze

      class << self
        def completion_items(line)
          open_attribute_match = line.match(ATTRIBUTE_REGEXP)
          return [] unless open_attribute_match

          items = []
          open_char = open_attribute_match[1]
          set_char = open_char == "{" ? ": " : "="

          # Add global attributes
          items += global_attribute_completions(set_char)

          # Add tag-specific attributes if context available
          items += tag_specific_completions(line, set_char)

          items
        end

        def extract_current_tag(line)
          return ::Regexp.last_match(1) if line =~ /%([\w:-]+)/

          nil
        end

        def global_attribute_completions(set_char)
          wrapper = set_char == ":" ? "\"" : ""

          GLOBAL_ATTRIBUTES.map do |attr|
            {
              label: attr,
              kind: Constant::CompletionItemKind::PROPERTY,
              detail: "HTML attribute",
              documentation: "Global HTML attribute: #{attr}",
              insert_text: attr.end_with?("-") ? "#{wrapper}#{attr}$1#{wrapper}#{set_char}$0" : "#{attr}#{set_char}",
              insert_text_format: attr.end_with?("-") ? Constant::InsertTextFormat::SNIPPET : Constant::InsertTextFormat::PLAIN_TEXT
            }
          end
        end

        def tag_specific_completions(line, set_char)
          tag = extract_current_tag(line)
          return [] unless tag && TAG_SPECIFIC_ATTRIBUTES.key?(tag)

          attributes = TAG_SPECIFIC_ATTRIBUTES[tag] || []
          attributes.map do |attr|
            {
              label: attr,
              kind: Constant::CompletionItemKind::PROPERTY,
              detail: "#{tag} attribute",
              documentation: "Attribute for <#{tag}> element",
              insert_text: "#{attr}#{set_char}"
            }
          end
        end
      end
    end
  end
end
