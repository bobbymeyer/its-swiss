require_relative "boot"

# Only the frameworks the library touches. A typographic gem has no database,
# no jobs and no mail, and booting them would only give the suite more ways to
# fail for reasons that are nothing to do with the CSS.
require "rails"
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "propshaft"
require "importmap-rails"

require "its_swiss"

module Dummy
  class Application < Rails::Application
    config.load_defaults 8.0
    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.secret_key_base = "its-swiss-dummy-application-secret-key-base"
    config.consider_all_requests_local = true
    config.action_dispatch.show_exceptions = :none
    config.logger = ActiveSupport::Logger.new(IO::NULL)
  end
end
