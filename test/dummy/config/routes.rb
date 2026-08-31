Rails.application.routes.draw do
  root "pages#show"
  get "page", to: "pages#show"
  get "other", to: "pages#other"
  get "bare", to: "pages#bare"

  # As the installer mounts it: development only, and the engine refuses it
  # anywhere the configuration has not asked for it.
  mount ItsSwiss::Engine => "/its-swiss"
end
