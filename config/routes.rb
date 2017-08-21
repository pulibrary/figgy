# frozen_string_literal: true
Rails.application.routes.draw do
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }, skip: [:passwords, :registration]
  devise_scope :user do
    get 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
    get 'users/auth/cas', to: 'users/omniauth_authorize#passthru', defaults: { provider: :cas }, as: "new_user_session"
  end
  mount Hydra::RoleManagement::Engine => '/'
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  mount Blacklight::Engine => '/'
  root to: "catalog#index"
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  # Consider moving these to Valhalla
  scope '/concern' do
    resources :file_sets
    resources :scanned_resources do
      member do
        get :file_manager
        get :structure
        get :manifest, defaults: { format: :json }
        post :browse_everything_files
        get :pdf
      end
    end
    get '/scanned_resources/:parent_id/new', to: 'scanned_resources#new', as: :parent_new_scanned_resource
  end

  resources :collections do
    member do
      get :manifest, defaults: { format: :json }
    end
  end

  get '/catalog/parent/:parent_id/:id', to: 'catalog#show', as: :parent_solr_document
  get "/iiif/lookup/:prefix/:naan/:arkid", to: 'catalog#lookup_manifest', as: :lookup_manifest

  mount BrowseEverything::Engine => '/browse'
  mount Valhalla::Engine => '/'

  if Rails.env.development? || Rails.env.test?
    mount Riiif::Engine => '/image-service', as: 'riiif'
  end

  require 'sidekiq/web'
  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end
end
