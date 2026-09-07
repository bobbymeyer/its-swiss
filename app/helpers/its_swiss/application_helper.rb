module ItsSwiss
  # The library's markup contracts. Each of these exists because the markup it
  # writes carries a detail that is easy to leave out by hand and silent when
  # it is missing.
  module ApplicationHelper
    # Six link tags rather than the one file that imports the six. An @import
    # is a request the browser cannot start until it has read the file that
    # asks for it, so the single file is a waterfall six deep — it is still
    # shipped, for anything that is not Rails and can afford the wait.
    #
    # The order matters less than it looks like it does: every file states its
    # own cascade layer, so these resolve the same way whatever order they
    # arrive in. It is written in order anyway, because a file that has not
    # arrived yet is a file whose layer has not been declared.
    #
    # Ahead of them, one line of script: whether this browser honours what a
    # @font-face says about its metrics, which is what puts the baseline on
    # the under edge of every line. Where it does not — Safari — the document
    # is marked and the trim in type.css that does the same job the long way
    # steps in. Inline and first, because it has to have run before the first
    # layout, and a class added after paint is a page that moves.
    def its_swiss_stylesheet_tags(**options)
      safe_join([
        tag.script(ItsSwiss::METRIC_OVERRIDES_SCRIPT.html_safe), # rubocop:disable Rails/OutputSafety -- a constant
        stylesheet_link_tag(*ItsSwiss::STYLESHEETS.map { |name| "its_swiss/#{name}" },
          **{ "data-turbo-track": "reload" }.merge(options))
      ], "\n")
    end

    # The application's typeface, declared under the library's face names.
    #
    # The library sets every register in a face named for its ratio of
    # leading to size — its-swiss-150, its-swiss-200, its-swiss-100 — each an
    # @font-face over the machine's own grotesque with its ascent set to that
    # ratio, so the baseline is the under edge of the line box. An
    # application that has a typeface declares it under the same names with
    # the same descriptors, and this writes those declarations: one file for
    # the regular and one for the bold, or one variable file carrying both,
    # and a monospace if there is one.
    #
    #   <%= its_swiss_typeface regular: "inter-regular.woff2", bold: "inter-bold.woff2" %>
    #   <%= its_swiss_typeface variable: "inter.woff2", mono: "jetbrains-mono.woff2" %>
    #   <%= its_swiss_typeface variable: "inter.woff2", family: "Inter" %>
    #
    # family: declares the same files under the font's own name as well, with
    # the font's own metrics. A control's text is set in --font-family rather
    # than on a face, so an application that names its typeface there needs
    # the name to resolve — or its fields are set in the machine's grotesque
    # while the page around them is set in its own.
    #
    # Unlayered, which is how it wins: a name defined outside a layer beats
    # the same name defined inside one, the way the application's rules beat
    # the library's. Put it after the library's stylesheets all the same, for
    # a browser that resolves a name by order rather than by layer.
    def its_swiss_typeface(regular: nil, bold: nil, variable: nil, mono: nil, family: nil)
      raise ArgumentError, "a regular file or a variable one" unless regular || variable
      raise ArgumentError, "a variable file carries both weights" if variable && (regular || bold)

      weights = variable ? { "100 900" => variable } : { "400" => regular, "700" => bold }.compact

      faces = ItsSwiss::FACES.flat_map do |family_name, ratio|
        weights.map { |weight, file| its_swiss_face(family_name, file, ratio, weight: weight) }
      end
      faces += ItsSwiss::MONO_FACE.map { |family_name, ratio| its_swiss_face(family_name, mono, ratio) } if mono
      faces += weights.map { |weight, file| its_swiss_face(family, file, nil, weight: weight) } if family

      tag.style(faces.join("\n").html_safe) # rubocop:disable Rails/OutputSafety -- every value is a number or a JSON-quoted path
    end

    # A destination, and whether you are already there. aria-current rather
    # than a class alone: the CSS gives the current item the accent and the
    # weight, and neither of those is audible.
    #
    # `current` is passed rather than worked out, because only the application
    # knows that /palettes/12 is still the Palettes destination.
    def nav_link_to(name, url, current: nil, **options, &block)
      current = current_page?(url) if current.nil?
      options[:"aria-current"] = "page" if current

      link_to(name, url, **options, &block)
    end

    # A destination in the nav that opens into destinations: a details
    # element with the label as its summary and the block as its list, so it
    # opens and closes with no script. current: when one of the destinations
    # inside is where you are, the summary carries the accent and the weight
    # the way a current link does.
    #
    #   <%= nav_menu "Tools", current: in_a_tool? do %>
    #     <%= nav_link_to "Pandatone", "/pandatone", current: in_engine?(pandatone) %>
    #   <% end %>
    def nav_menu(label, current: false, &block)
      tag.details(class: token_list("menu", ("menu--current" if current))) do
        safe_join([ tag.summary(label), tag.div(capture(&block), class: "menu__list") ])
      end
    end

    # A value on screen exists to be taken somewhere else, so it is a button
    # that copies itself. The value stays visible text inside it, which is
    # what keeps it usable when the clipboard is not available at all.
    def copy_button(value, **options)
      options[:class] = token_list("copy", options[:class])

      tag.button(value, type: "button", **options,
        data: {
          controller: "its-swiss-clipboard",
          action: "its-swiss-clipboard#copy",
          its_swiss_clipboard_text_value: value
        },
        aria: { label: "Copy #{value}" })
    end

    # What to call the application when a page has not titled itself. Rails
    # already knows: the module the application is defined in.
    def its_swiss_application_name
      Rails.application.class.module_parent_name.underscore.humanize
    end

    # Which page numbers a run of them should show. Elided around the current
    # page and at both ends, because a hundred numbers is not a control —
    # nil is where the gap goes.
    def its_swiss_page_numbers(page, pages, window: 2)
      shown = [ 1, pages, *((page - window)..(page + window)) ].select { |n| n.between?(1, pages) }.uniq.sort

      shown.each_with_object([]) do |number, run|
        run << nil if run.any? && number - run.last.to_i > 1
        run << number
      end
    end

    FONT_FORMATS = { ".woff2" => "woff2", ".woff" => "woff", ".ttf" => "truetype", ".otf" => "opentype" }.freeze

    # With a ratio, a face whose ascent is that ratio and whose descent is
    # nothing; without one, the font under its own name with its own metrics.
    def its_swiss_face(family, file, ratio, weight: nil)
      source = "url(#{asset_path(file).to_json})"
      source += %( format("#{FONT_FORMATS[File.extname(file)]}")) if FONT_FORMATS[File.extname(file)]
      ascent = (ratio * 100).to_f.round(4).to_s.sub(/\.0\z/, "") if ratio

      [ "@font-face {",
        "  font-family: #{family.to_json};",
        ("  font-weight: #{weight};" if weight),
        "  src: #{source};",
        ("  ascent-override: #{ascent}%;" if ratio),
        ("  descent-override: 0%;" if ratio),
        ("  line-gap-override: 0%;" if ratio),
        "}" ].compact.join("\n")
    end
    private :its_swiss_face

    # What a page is and what can be done to it: the title, a lede when the
    # page has one, and the actions in the block. One shape for every page,
    # and the document is titled from it unless the view has titled itself.
    #
    #   <%= page_head "Palettes", lede: "Every palette in the library." do %>
    #     <%= link_to "New palette", new_palette_path, class: "button button--primary" %>
    #   <% end %>
    def page_head(title, lede: nil, &block)
      content_for(:title, strip_tags(title.to_s)) unless content_for?(:title)
      actions = capture(&block) if block

      tag.header(class: "page-head") do
        safe_join([
          tag.div(class: "page-head__title") do
            safe_join([ tag.h1(title, class: "page-title"), (tag.p(lede, class: "lede") if lede) ].compact)
          end,
          (tag.div(actions, class: "page-head__actions run") if actions.present?)
        ].compact)
      end
    end

    # One register of a filter block: a quiet label, then the choices, each
    # a name, a URL and whether it is the one in force. Filtering and
    # ordering are the same kind of control — pick one of a handful — so
    # they are built the same way and told apart by their label.
    #
    #   <%= filter_register "Tagged", [ [ "All", colors_path, params[:tag].blank? ],
    #                                   *tags.map { |t| [ t, colors_path(tag: t), params[:tag] == t ] } ],
    #         name: "tag" %>
    #
    # The one in force carries aria-current, which the CSS colours and
    # weights, and a test can find without reading a class.
    def filter_register(label, choices, name: nil)
      tag.div(class: "filter", data: { filter: name }) do
        safe_join([
          tag.span(label, class: "filter__label"),
          tag.div(class: "filter__choices") do
            safe_join(choices.map { |text, url, current| link_to(text, url, aria: { current: ("true" if current) }) })
          end
        ])
      end
    end

    # A search that narrows a list as you type, into the Turbo Frame named.
    # The form belongs outside that frame, so only the results are replaced
    # and the field keeps its cursor; the button is for a browser that runs
    # no script, and the controller takes it away once it has connected.
    #
    #   <%= search_form palettes_path, frame: "palettes", keep: { tag: params[:tag], sort: params[:sort] } %>
    #
    # keep: the other choices on the page, carried as hidden fields so a
    # search does not drop the tag or the order you were reading in. The
    # host registers the controller as its-swiss-live-search.
    def search_form(url, frame:, param: :q, label: "Search", value: nil, keep: {}, delay: nil, **options)
      value = params[param] if value.nil? && respond_to?(:params)
      data = { controller: "its-swiss-live-search", action: "input->its-swiss-live-search#search",
               turbo_frame: frame, its_swiss_live_search_delay_value: delay }.compact

      form_with(url: url, method: :get, class: token_list("form form--inline", options[:class]), data: data) do
        safe_join([
          *keep.compact_blank.map { |name, kept| hidden_field_tag(name, kept, id: nil) },
          tag.div(class: "field field--inline") do
            safe_join([ label_tag(param, label), search_field_tag(param, value, autocomplete: "off") ])
          end,
          submit_tag(label, name: nil, class: "button", data: { its_swiss_live_search_target: "submit" })
        ])
      end
    end

    # form_with, already holding the library's builder. An application that
    # wants its own builder still can; this is the shorthand for the case
    # where it does not.
    def its_swiss_form_with(**options, &block)
      form_with(**{ builder: ItsSwiss::FormBuilder, class: "form" }.merge(options), &block)
    end
  end
end
