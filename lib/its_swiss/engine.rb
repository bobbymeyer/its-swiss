require "rails/engine"

module ItsSwiss
  # Isolated, so the specimen's routes and helpers cannot collide with the
  # application's. The stylesheets are not isolated by anything — CSS has one
  # global namespace and pretending otherwise would mean prefixing every
  # class in the library.
  class Engine < ::Rails::Engine
    isolate_namespace ItsSwiss

    # Propshaft picks up an engine's app/assets/stylesheets on its own. The
    # JavaScript is not in that default set, and it is one file, so it is
    # added here rather than left to the application to remember.
    initializer "its_swiss.assets" do |app|
      next unless app.config.respond_to?(:assets)

      app.config.assets.paths << root.join("app/assets/javascripts")
    end

    # Pinned from the engine rather than written into the application's
    # importmap by the generator: an application that upgrades the gem should
    # get the new file without re-running a generator, and a pin it never
    # wrote is a pin it cannot leave stale.
    initializer "its_swiss.importmap", before: "importmap" do |app|
      next unless app.respond_to?(:importmap)

      app.config.importmap.paths << root.join("config/importmap.rb")
      # Reloading in development watches the pinned files for changes; a gem
      # loaded from a path: dependency is being edited, so it is watched too.
      app.config.importmap.cache_sweepers << root.join("app/assets/javascripts")
    end

    config.to_prepare do
      ActiveSupport.on_load(:action_view) do
        include ItsSwiss::ApplicationHelper
      end
    end
  end
end
