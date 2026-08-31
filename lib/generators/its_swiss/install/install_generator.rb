require "rails/generators/base"

module ItsSwiss
  module Generators
    # Four things, each of them easy to get wrong by hand and quiet when it is
    # wrong. Everything else the library does is a gem dependency and needs no
    # generator at all: Propshaft finds the stylesheets, and the engine pins
    # its own JavaScript so that upgrading the gem is enough to get the new
    # file.
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Fills in the slots its-swiss leaves for an application: the accent, the typeface, the grid."

      def create_theme_stylesheet
        template "theme.css", "app/assets/stylesheets/theme.css"
      end

      # An application that has already chosen a layout has chosen it.
      def render_through_the_shell
        controller = "app/controllers/application_controller.rb"
        return say_status(:skip, "#{controller} not found", :yellow) unless exists?(controller)

        contents = read(controller)
        return say_status(:skip, "#{controller} already chooses a layout", :yellow) if contents.match?(/^\s*layout\s/)

        inject_into_class controller, "ApplicationController", %(  layout "its_swiss/shell"\n)
      end

      # Development only, and the controller refuses it a second time: the
      # specimen names every component the library has, and a route is a line
      # in a file someone can move.
      def mount_the_specimen
        routes = "config/routes.rb"
        return say_status(:skip, "#{routes} not found", :yellow) unless exists?(routes)
        return say_status(:skip, "the specimen is already mounted", :yellow) if read(routes).include?("ItsSwiss::Engine")

        inject_into_file routes, after: /Rails\.application\.routes\.draw do\n/ do
          <<~RUBY.indent(2)
            if Rails.env.development?
              mount ItsSwiss::Engine => "/its-swiss"
            end

          RUBY
        end
      end

      def say_what_is_left
        say <<~TEXT

          its-swiss is installed. What is left is yours:

            app/assets/stylesheets/theme.css   the accent, the typeface, the grid
            /its-swiss/specimen                every component, rendered twice

          The library ships no typeface and no palette. Set --accent to one
          colour and read the specimen with it unset: if the page still works,
          the value scale is doing the work.
        TEXT
      end
      private
        # Thor writes relative to destination_root; reading has to as well, or
        # the guards above interrogate whatever directory the generator was
        # invoked from.
        def exists?(path) = File.exist?(File.expand_path(path, destination_root))

        def read(path) = File.read(File.expand_path(path, destination_root))
    end
  end
end
