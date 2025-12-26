# frozen_string_literal: true

module HamlLsp
  module Haml
    # Module to provide HAML attribute completions
    module AttributesProvider
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

      # HAML-specific attributes
      HAML_ATTRIBUTES = [
        { label: "{", detail: "Ruby hash attributes",
          documentation: 'HAML hash attributes syntax: %tag{attr: "value"}' },
        { label: "(", detail: "HTML-style attributes",
          documentation: 'HAML HTML-style attributes: %tag(attr="value")' },
        { label: ".", detail: "Class shortcut", documentation: "HAML class syntax: %tag.classname" },
        { label: "#", detail: "ID shortcut", documentation: "HAML ID syntax: %tag#idname" }
      ].freeze

      class << self
        def completion_items(context = {})
          items = []

          # Add global attributes
          items += global_attribute_completions

          # Add HAML-specific syntax
          items += haml_attribute_completions

          # Add tag-specific attributes if context available
          items += tag_specific_completions(context[:tag]) if context[:tag]

          items
        end

        private

        def global_attribute_completions
          GLOBAL_ATTRIBUTES.map do |attr|
            {
              label: attr,
              kind: 10, # Property
              detail: "HTML attribute",
              documentation: "Global HTML attribute: #{attr}",
              insert_text: attr.end_with?("-") ? attr : "#{attr}="
            }
          end
        end

        def haml_attribute_completions
          HAML_ATTRIBUTES.map do |attr|
            {
              label: attr[:label],
              kind: 15, # Snippet
              detail: attr[:detail],
              documentation: attr[:documentation],
              insert_text: attr[:label]
            }
          end
        end

        def tag_specific_completions(tag)
          attributes = TAG_SPECIFIC_ATTRIBUTES[tag] || []
          attributes.map do |attr|
            {
              label: attr,
              kind: 10, # Property
              detail: "#{tag} attribute",
              documentation: "Specific attribute for <#{tag}> element",
              insert_text: "#{attr}="
            }
          end
        end
      end
    end
  end
end
