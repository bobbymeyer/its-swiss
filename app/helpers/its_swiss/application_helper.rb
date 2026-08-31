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
    def its_swiss_stylesheet_tags(**options)
      stylesheet_link_tag(*ItsSwiss::STYLESHEETS.map { |name| "its_swiss/#{name}" },
        **{ "data-turbo-track": "reload" }.merge(options))
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

    # form_with, already holding the library's builder. An application that
    # wants its own builder still can; this is the shorthand for the case
    # where it does not.
    def its_swiss_form_with(**options, &block)
      form_with(**{ builder: ItsSwiss::FormBuilder, class: "form" }.merge(options), &block)
    end
  end
end
