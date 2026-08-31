Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.public_file_server.enabled = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = :none
  config.action_controller.allow_forgery_protection = false
end
