# frozen_string_literal: true

module HamlLsp
  module Completion
    # Module to provide HAML tag completions
    module Tags
      TAG_REGEXP = /%[\w:-]*?$/

      HTML_TAGS = %w[
        a abbr address area article aside audio
        b base bdi bdo blockquote body br button
        canvas caption cite code col colgroup
        data datalist dd del details dfn dialog div dl dt
        em embed
        fieldset figcaption figure footer form
        h1 h2 h3 h4 h5 h6 head header hgroup hr html
        i iframe img input ins
        kbd
        label legend li link
        main map mark meta meter
        nav noscript
        object ol optgroup option output
        p param picture pre progress
        q
        rp rt ruby
        s samp script section select small source span strong style sub summary sup svg
        table tbody td template textarea tfoot th thead time title tr track
        u ul
        var video
        wbr
      ].freeze

      class << self
        def completion_items(line)
          return [] unless line.match?(TAG_REGEXP)

          tag_completions
        end

        def tag_completions
          HTML_TAGS.map do |tag|
            {
              label: tag,
              kind: Constant::CompletionItemKind::KEYWORD,
              detail: "HTML <#{tag}> element",
              insert_text: tag
            }
          end
        end
      end
    end
  end
end
