# frozen_string_literal: true

module HamlLsp
  module Haml
    # Module to provide HAML tag completions
    module TagsProvider
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

      HAML_TAGS = %w[
        %div %span %p %a %h1 %h2 %h3 %h4 %h5 %h6
        %ul %ol %li %dl %dt %dd
        %table %thead %tbody %tfoot %tr %th %td
        %form %input %button %select %option %textarea %label
        %header %footer %nav %section %article %aside %main
        %img %figure %figcaption
        %strong %em %code %pre %blockquote
        %iframe %script %style %link %meta
      ].freeze

      class << self
        def completion_items
          html_completions + haml_completions
        end

        private

        def html_completions
          HTML_TAGS.map do |tag|
            {
              label: tag,
              kind: 14, # Keyword
              detail: "HTML tag",
              documentation: "HTML <#{tag}> element",
              insert_text: tag
            }
          end
        end

        def haml_completions
          HAML_TAGS.map do |tag|
            {
              label: tag,
              kind: 15, # Snippet
              detail: "HAML tag",
              documentation: "HAML #{tag} element",
              insert_text: "#{tag} "
            }
          end
        end
      end
    end
  end
end
