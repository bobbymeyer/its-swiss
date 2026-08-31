require "test_helper"
require "rails/generators/test_case"
require "generators/its_swiss/install/install_generator"

# The installer's job is to leave an application on the shape that scales.
# 0.1.0 did not: it named the shell as the controller's layout, which renders
# the shell but leaves nowhere to fill its slots once — so an application
# writes its masthead into every view before noticing. And it created
# theme.css without linking it, so an application that followed the README
# exactly got no accent and no grid, with no error anywhere.
class InstallGeneratorTest < Rails::Generators::TestCase
  tests ItsSwiss::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generator", __dir__)
  setup :prepare_destination
  setup :write_an_application

  test "creates the one file a consumer fills in" do
    run_generator

    assert_file "app/assets/stylesheets/theme.css" do |css|
      assert_match(/--accent:/, css, "the accent is the first thing a consumer sets")
      assert_match(/--font-family:/, css)
      assert_match(/--columns:/, css, "how many fields the problem has is the application's to say")
      assert_no_match(/@layer/, css, "an application's own CSS is unlayered, which is how it wins")
    end
  end

  # A nested layout, not a `layout` line. content_for has to run while a view
  # is rendering, and these slots are set once for the whole application.
  test "generates a layout that fills the shell's slots once" do
    run_generator

    assert_file "app/views/layouts/application.html.erb" do |layout|
      assert_match(/render template: "layouts\/its_swiss\/shell"/, layout,
        "without this the layout replaces the shell rather than filling it")

      %w[ :head :mark :nav ].each do |slot|
        assert_match(/content_for #{slot}/, layout, "#{slot} is not stubbed, so nothing shows an app where to put it")
      end
    end
  end

  # theme.css holds the accent and the grid. The shell links the library's six
  # stylesheets and stops, so nothing links this one unless the layout does.
  test "links the stylesheet it just created" do
    run_generator

    assert_file "app/views/layouts/application.html.erb", /stylesheet_link_tag "theme"/
  end

  # application.html.erb is the default layout's name, so naming it on the
  # controller as well says the same thing twice and invites the two to
  # disagree.
  test "leaves the application controller alone" do
    run_generator

    assert_file "app/controllers/application_controller.rb" do |controller|
      assert_no_match(/layout/, controller)
    end
  end

  test "mounts the specimen where it cannot answer in production" do
    run_generator

    assert_file "config/routes.rb" do |routes|
      assert_match(/if Rails\.env\.development\?/, routes)
      assert_match(/mount ItsSwiss::Engine => "\/its-swiss"/, routes)
    end
  end

  test "is safe to run twice" do
    run_generator
    run_generator [ "--force" ]

    assert_equal 1, File.read(File.join(destination_root, "config/routes.rb")).scan("mount ItsSwiss::Engine").size
  end

  private
    def write_an_application
      FileUtils.mkdir_p(File.join(destination_root, "app/controllers"))
      FileUtils.mkdir_p(File.join(destination_root, "config"))
      File.write(File.join(destination_root, "app/controllers/application_controller.rb"), <<~RUBY)
        class ApplicationController < ActionController::Base
        end
      RUBY
      File.write(File.join(destination_root, "config/routes.rb"), <<~RUBY)
        Rails.application.routes.draw do
          root "pages#show"
        end
      RUBY
    end
end
