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
  # Every file states its own layer, so linking these seven individually and
  # linking the single its-swiss.css that imports them resolve identically.
  STYLESHEETS = %w[ tokens faces reset type grid components transitions ].freeze

  # The faces the library sets type in, and the ascent each is declared with
  # as a ratio of its size. A face's ascent is the leading it will be set on:
  # with no descent and no line gap, that puts the baseline of every line on
  # the under edge of its line box, which is what registers a block of type
  # to the grid. Three, because the ladder in tokens.css produces three
  # ratios of leading to size, and one for code. The names are the ratios,
  # and the helper that declares an application's own typeface under them
  # reads the numbers from here.
  FACES = { "its-swiss-150" => 1.5, "its-swiss-200" => 2.0, "its-swiss-100" => 1.0 }.freeze
  MONO_FACE = { "its-swiss-mono" => 5 / 3r }.freeze

  # Marks the document when the browser does not honour a @font-face's metric
  # descriptors, which is what the faces rely on, so that the trim in type.css
  # steps in. Written inline ahead of the stylesheets by
  # its_swiss_stylesheet_tags and by the static specimen, and by anything else
  # that links the stylesheets by hand.
  METRIC_OVERRIDES_SCRIPT = %(if (!("ascentOverride" in FontFace.prototype)) document.documentElement.classList.add("no-metric-overrides")).freeze

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
