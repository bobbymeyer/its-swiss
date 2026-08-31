require "its_swiss/version"
require "its_swiss/engine" if defined?(Rails::Engine)

module ItsSwiss
  # Autoloaded rather than required: it subclasses ActionView's builder, which
  # does not exist until Action View has loaded, and this file is read while
  # the application is still assembling itself.
  autoload :FormBuilder, "its_swiss/form_builder"

  # The stylesheets, in the order their layers are declared. The gem's own
  # layer order is fixed here rather than left to whoever writes the <link>
  # tags: an application that loads type before tokens should still get the
  # cascade the library was designed with.
  #
  # Every file states its own layer, so linking these six individually and
  # linking the single its-swiss.css that imports them resolve identically.
  STYLESHEETS = %w[ tokens reset type grid components transitions ].freeze

  # The cascade layer everything the gem ships lives in. An application's own
  # CSS is unlayered, and unlayered rules beat every layered one regardless of
  # specificity — which is the boundary in the table made mechanical: the gem
  # is a base, and the app's grid and domain components win without anyone
  # having to count selectors or reach for !important.
  LAYER = "its-swiss".freeze

  class << self
    # Where a consumer says which of the gem's slots it fills. Nothing here
    # has a default the gem could reasonably pick for it.
    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end
  end

  class Configuration
    # The specimen is documentation and a regression fixture, not a page an
    # application serves. It stays off unless the environment asks for it, so
    # a route left mounted by accident cannot answer in production.
    attr_writer :specimen

    def specimen? = @specimen.nil? ? !!Rails.env.local? : @specimen
  end
end
