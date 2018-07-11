# frozen_string_literal: true
Rails.application.routes.draw do
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end

  post "/graphql", to: "graphql#execute", defaults: { format: :json }
  get "dashboard/fixity", to: "fixity_dashboard#show", as: "fixity_dashboard"

  resources :auth_tokens
  default_url_options Rails.application.config.action_mailer.default_url_options
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: "/catalog", controller: "catalog" do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete "clear"
    end
  end

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }, skip: [:passwords, :registration]
  devise_scope :user do
    get "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
    get "users/auth/cas", to: "users/omniauth_authorize#passthru", defaults: { provider: :cas }, as: "new_user_session"
  end
  resources :users, only: [:index, :create, :destroy]
  mount Hydra::RoleManagement::Engine => "/"
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: "/catalog", controller: "catalog" do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete "clear"
    end
  end

  mount Blacklight::Engine => "/"
  root to: "catalog#index"
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: "catalog", path: "/catalog", controller: "catalog" do
    concerns :searchable
  end

  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: "/catalog", controller: "catalog" do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete "clear"
    end
  end

  get "/downloads/:resource_id/file/:id", to: "downloads#show", as: :download

  scope "/concern" do
    resources :file_sets do
      member do
        put :derivatives
        get :text
      end
    end
    resources :scanned_resources do
      member do
        get :file_manager
        get :order_manager
        get :structure
        get :manifest, defaults: { format: :json }
        post :browse_everything_files
        get :pdf
      end
      collection do
        get "save_and_ingest/:id", action: :save_and_ingest
      end
    end
    resources :media_resources

    # Added for redirects for IIIF Manifests.
    resources :multi_volume_works, controller: "scanned_resources", only: [] do
      member do
        get :manifest, defaults: { format: :json }
      end
    end

    get "/scanned_resources/:parent_id/new", to: "scanned_resources#new", as: :parent_new_scanned_resource

    resources :simple_resources do
      member do
        get :file_manager
        get :order_manager
        get :manifest, defaults: { format: :json }
        post :browse_everything_files
        get :pdf
      end
    end

    get "/simple_resources/:parent_id/new", to: "simple_resources#new", as: :parent_new_simple_resource

    resources :ephemera_projects do
      resources :templates, only: [:new, :create, :destroy]
      resources :ephemera_fields
      member do
        get :folders, defaults: { format: :json }
      end
      member do
        get :manifest, defaults: { format: :json }
      end
    end
    get "/ephemera_projects/:parent_id/templates/new/:model_class", to: "templates#new", as: :parent_new_template
    get "/ephemera_projects/:parent_id/box" => "ephemera_boxes#new", as: "ephemera_project_add_box"
    get "/ephemera_projects/:parent_id/field", to: "ephemera_fields#new", as: :ephemera_project_add_field

    resources :ephemera_boxes do
      member do
        get :attach_drive
      end
      member do
        get :folders, defaults: { format: :json }
      end
    end

    resources :ephemera_folders do
      member do
        get :file_manager
        get :order_manager
        get :structure
        get :manifest, defaults: { format: :json }
        post :browse_everything_files
        get :pdf
      end
    end
    get "/ephemera_projects/:parent_id/ephemera_folders/new", to: "ephemera_folders#new", as: :boxless_new_ephemera_folder
    get "/ephemera_boxes/:parent_id/ephemera_folders/new", to: "ephemera_folders#new", as: :parent_new_ephemera_box

    resources :ephemera_vocabularies
    get "/ephemera_vocabularies/:parent_id/ephemera_categories/new", to: "ephemera_vocabularies#new", as: :ephemera_vocabulary_add_category

    resources :ephemera_fields
    resources :ephemera_terms
    get "/ephemera_vocabularies/:parent_id/ephemera_terms/new", to: "ephemera_terms#new", as: :ephemera_vocabulary_add_term

    resources :scanned_maps do
      member do
        get :file_manager
        get :geoblacklight, defaults: { format: :json }
        get :manifest, defaults: { format: :json }
        get :order_manager
        get :pdf
        get :structure
        post :browse_everything_files
      end
    end
    get "/scanned_maps/:parent_id/new", to: "scanned_maps#new", as: :parent_new_scanned_map
    put "/scanned_maps/:id/extract_metadata/:file_set_id", to: "scanned_maps#extract_metadata", as: :scanned_maps_extract_metadata
    patch "/scanned_maps/:id/attach_to_parent", to: "scanned_maps#attach_to_parent", as: :scanned_maps_attach_to_parent, defaults: { format: :json }
    patch "/scanned_maps/:id/remove_from_parent", to: "scanned_maps#remove_from_parent", as: :scanned_maps_remove_from_parent, defaults: { format: :json }

    resources :vector_resources do
      member do
        get :file_manager
        get :geoblacklight, defaults: { format: :json }
        post :browse_everything_files
      end
    end
    get "/vector_resources/:parent_id/new", to: "vector_resources#new", as: :parent_new_vector_resource
    put "/vector_resources/:id/extract_metadata/:file_set_id", to: "vector_resources#extract_metadata", as: :vector_resources_extract_metadata
    patch "/vector_resources/:id/attach_to_parent", to: "vector_resources#attach_to_parent", as: :vector_resources_attach_to_parent, defaults: { format: :json }
    patch "/vector_resources/:id/remove_from_parent", to: "vector_resources#remove_from_parent", as: :vector_resources_remove_from_parent, defaults: { format: :json }

    resources :raster_resources do
      member do
        get :file_manager
        get :geoblacklight, defaults: { format: :json }
        post :browse_everything_files
      end
    end
    get "/raster_resources/:parent_id/new", to: "raster_resources#new", as: :parent_new_raster_resource
    put "/raster_resources/:id/extract_metadata/:file_set_id", to: "raster_resources#extract_metadata", as: :raster_resources_extract_metadata
    patch "/raster_resources/:id/attach_to_parent", to: "raster_resources#attach_to_parent", as: :raster_resources_attach_to_parent, defaults: { format: :json }
    patch "/raster_resources/:id/remove_from_parent", to: "raster_resources#remove_from_parent", as: :raster_resources_remove_from_parent, defaults: { format: :json }
  end

  resources :collections do
    member do
      get :manifest, defaults: { format: :json }
    end
  end
  get "/iiif/collections", defaults: { format: :json }, to: "collections#index_manifest", as: :index_manifest

  resources :archival_media_collections
  get "archival_media_collections/:id/ark_report", to: "archival_media_collections#ark_report", as: :archival_media_collections_ark_report

  get "/catalog/parent/:parent_id/:id", to: "catalog#show", as: :parent_solr_document
  get "/iiif/lookup/:prefix/:naan/:arkid", to: "catalog#lookup_manifest", as: :lookup_manifest

  get "/reports/identifiers_to_reconcile", to: "reports#identifiers_to_reconcile", as: :identifiers_to_reconcile

  get "bulk_ingest/:resource_type", to: "bulk_ingest#show", as: "bulk_ingest_show"
  post "bulk_ingest/:resource_type/browse_everything_files", to: "bulk_ingest#browse_everything_files", as: "browse_everything_files_bulk_ingest"

  mount BrowseEverything::Engine => "/browse"

  if Rails.env.development? || Rails.env.test?
    mount Riiif::Engine => "/image-service", as: "riiif"
  end

  require "sidekiq/web"
  authenticate :user do
    mount Sidekiq::Web => "/sidekiq"
  end
end
