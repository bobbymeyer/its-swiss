ENV["RAILS_ENV"] = "test"

require "rails"
require_relative "dummy/config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Where the library's own source lives, for the tests that read the CSS
    # rather than render it.
    ROOT = Pathname.new(File.expand_path("..", __dir__)).freeze
    STYLESHEETS = ROOT.join("app/assets/stylesheets/its_swiss").freeze

    def stylesheet(name)
      STYLESHEETS.join("#{name}.css").read
    end

    def every_stylesheet
      ItsSwiss::STYLESHEETS.to_h { |name| [ name, stylesheet(name) ] }
    end

    # A stylesheet with its comments taken out. Nearly every guard in this
    # suite is a grep, and these files carry more prose than most: a rule
    # explaining why the library does not do something would otherwise read as
    # the library doing it.
    def rules_in(name)
      stylesheet(name).gsub(%r{/\*.*?\*/}m, "")
    end
  end
end
