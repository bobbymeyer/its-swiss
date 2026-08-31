require "test_helper"
require "rails/generators/test_case"
require "generators/its_swiss/install/install_generator"

# The installer's job is the four things that are easy to get wrong by hand
# and quiet when they are wrong: the layout an application renders through,
# the file where it fills the library's slots, and a specimen route that
# cannot answer outside development.
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

  test "renders the application through the shell" do
    run_generator

    assert_file "app/controllers/application_controller.rb", /layout "its_swiss\/shell"/
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
    assert_equal 1, File.read(File.join(destination_root, "app/controllers/application_controller.rb"))
      .scan("its_swiss/shell").size
  end

  test "leaves an application that already has its own layout alone" do
    File.write(File.join(destination_root, "app/controllers/application_controller.rb"), <<~RUBY)
      class ApplicationController < ActionController::Base
        layout "marketing"
      end
    RUBY

    run_generator

    assert_file "app/controllers/application_controller.rb" do |controller|
      assert_match(/layout "marketing"/, controller)
      assert_no_match(/layout "its_swiss\/shell"/, controller,
        "an application that has chosen a layout has chosen it")
    end
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
