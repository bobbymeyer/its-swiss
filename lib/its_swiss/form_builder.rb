module ItsSwiss
  # One shape for every field: a label, a control, and — when there is
  # something to say — a hint or the reason it was refused.
  #
  # Written by a builder rather than by hand because the parts that get left
  # out by hand are the parts nobody sees missing. A label whose `for` does not
  # match its input is a label that does not enlarge the target. A hint beside
  # a control is a hint a screen reader never reaches. A refused field coloured
  # by CSS alone is a refusal that only some readers get.
  class FormBuilder < ActionView::Helpers::FormBuilder
    # Everything that is a line of text under a rule. They differ only in the
    # keyboard a phone puts up, which is not a difference the markup has.
    TEXT_FIELDS = %i[
      text_field email_field password_field number_field url_field
      telephone_field phone_field search_field date_field time_field
      datetime_field color_field text_area
    ].freeze

    TEXT_FIELDS.each do |control|
      define_method(control) do |method, options = {}|
        field(method, options) { |opts| super(method, opts) }
      end
    end

    def select(method, choices = nil, options = {}, html_options = {}, &block)
      field(method, html_options) do |opts|
        super(method, choices, options, opts, &block)
      end
    end

    def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
      field(method, html_options) do |opts|
        super(method, collection, value_method, text_method, options, opts)
      end
    end

    # A checkbox and its label are a pair on one line — the label says what
    # ticking it means, and reading that above an empty box says nothing.
    def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      field(method, options, label_beside: true) do |opts|
        super(method, opts, checked_value, unchecked_value)
      end
    end

    def radio_button(method, tag_value, options = {})
      field(method, options, label_beside: true, label_for_value: tag_value) do |opts|
        super(method, tag_value, opts)
      end
    end

    # A <button>, not an <input>: an input's label is an attribute, and the
    # one thing this style asks of a button is that it be a box with words in
    # it. Primary unless the caller says otherwise, because a form has one
    # thing it is for.
    def submit(value = nil, options = {})
      value ||= submit_default_value
      options = { class: "button button--primary" }.merge(options.symbolize_keys)

      @template.tag.button(value, **options, type: "submit")
    end

    # The wrapper on its own, for a control the library does not know about.
    def field(method, options = {}, label_beside: false, label_for_value: nil, &control)
      options = options.symbolize_keys
      hint, label_option = options.delete(:hint), options.delete(:label)
      errors = errors_on(method)

      ids = describers(method, hint, errors)
      options[:"aria-describedby"] = ids.join(" ") if ids.any?
      options[:"aria-invalid"] = "true" if errors.any?

      label = rendered_label(method, label_option, label_for_value)
      options[:"aria-label"] ||= default_label(method) if label.nil?
      body = @template.capture { control.call(options) }
      body = @template.tag.span(safe_join([ body, label ]), class: "choice") if label_beside && label

      @template.tag.div(class: field_classes(errors)) do
        safe_join([
          (label unless label_beside),
          body,
          hint_tag(method, hint),
          *errors.map.with_index { |message, index| error_tag(method, index, message) }
        ].compact)
      end
    end

    private
      def field_classes(errors)
        errors.any? ? "field field--invalid" : "field"
      end

      # `label: false` hides the label; it does not remove it. Something has to
      # name the control, so the name moves onto the control itself.
      def rendered_label(method, option, for_value)
        return nil if option == false

        label(method, option.is_a?(String) ? option : nil, value: for_value)
      end

      # A control whose label is hidden still needs a name, and aria-label is
      # where it goes. Applied to the control rather than the wrapper because
      # the wrapper is a div and names nothing.
      def describers(method, hint, errors)
        ids = []
        ids << hint_id(method) if hint
        errors.each_index { |index| ids << error_id(method, index) }
        ids
      end

      def hint_tag(method, hint)
        return nil unless hint

        @template.tag.p(hint, class: "hint", id: hint_id(method))
      end

      def error_tag(method, index, message)
        @template.tag.p(message, class: "field__error", id: error_id(method, index))
      end

      # What the label would have said, for a control whose label is hidden.
      def default_label(method)
        @object_name.to_s.camelize.safe_constantize&.human_attribute_name(method) ||
          method.to_s.humanize
      end

      def hint_id(method) = "#{field_id(method)}_hint"

      def error_id(method, index) = "#{field_id(method)}_error_#{index}"

      # Full messages, so "cannot be blank" reads as a sentence about the
      # field rather than as a fragment floating under it.
      def errors_on(method)
        return [] unless @object.respond_to?(:errors)

        Array(@object.errors.full_messages_for(method))
      end

      def safe_join(parts) = @template.safe_join(parts)
  end
end
