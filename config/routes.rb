ItsSwiss::Engine.routes.draw do
  # Mounted by the installer under `if Rails.env.development?`, and refused by
  # the controller as well: a route is a line in a file someone can move, and
  # the specimen names every component the library has.
  get "specimen", to: "specimen#show", as: :specimen
end
