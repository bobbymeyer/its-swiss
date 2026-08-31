require "test_helper"

# What the engine has to get right for an application to get the library by
# adding one line to a Gemfile.
class EngineTest < ActiveSupport::TestCase
  test "the declared stylesheets are the stylesheets that ship" do
    on_disk = STYLESHEETS.glob("*.css").map { |path| path.basename(".css").to_s }

    assert_equal ItsSwiss::STYLESHEETS.sort, (on_disk - %w[ specimen ]).sort,
      "a core stylesheet that is not in ItsSwiss::STYLESHEETS is never linked, and never says so"
  end

  test "Propshaft can find the library's assets" do
    paths = Rails.application.config.assets.paths.map(&:to_s)

    assert_includes paths, ItsSwiss::Engine.root.join("app/assets/stylesheets").to_s
    assert_includes paths, ItsSwiss::Engine.root.join("app/assets/javascripts").to_s,
      "an engine's JavaScript is not on Propshaft's default path; the engine has to add it"
  end

  # Pinned from the engine rather than written into the application's
  # importmap by the generator: an application that upgrades the gem should
  # get the new file without re-running anything, and a pin it never wrote is
  # a pin it cannot leave stale.
  test "pins its JavaScript itself" do
    assert_includes Rails.application.config.importmap.paths.map(&:to_s),
      ItsSwiss::Engine.root.join("config/importmap.rb").to_s
    assert_match %r{its_swiss/clipboard_controller}, Rails.application.importmap.to_json(resolver: ApplicationController.helpers)
  end

  test "the gem ships everything it needs at runtime" do
    spec = Gem::Specification.load(ROOT.join("its-swiss.gemspec").to_s)

    %w[
      app/assets/stylesheets/its-swiss.css
      app/assets/stylesheets/its_swiss/tokens.css
      app/assets/javascripts/its_swiss/clipboard_controller.js
      app/views/layouts/its_swiss/shell.html.erb
      config/importmap.rb
      lib/generators/its_swiss/install/templates/theme.css
      lib/generators/its_swiss/install/templates/application.html.erb
    ].each { |path| assert_includes spec.files, path, "#{path} would not be in the built gem" }
  end

  # The specimen names every component the library has, which is exactly what
  # should not be reachable from a production application by accident.
  test "the specimen follows the environment unless told otherwise" do
    assert ItsSwiss.config.specimen?, "the test environment is local, so the specimen answers"

    ItsSwiss.configure { |config| config.specimen = false }
    assert_not ItsSwiss.config.specimen?
  ensure
    ItsSwiss.configure { |config| config.specimen = nil }
  end
end
