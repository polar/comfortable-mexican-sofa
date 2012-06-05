[
 "test_app/controllers/trials_controller",
 "test_app/models/trial",
 "test_app/lib/tags/trial_tag"
].each do |f|
  require f
end

ActionController::Base.prepend_view_path "test/test_app/views"

Rails.application.routes.draw do
  resources :trials
  mount ComfortableMexicanSofa::Engine, :at => "/"
end