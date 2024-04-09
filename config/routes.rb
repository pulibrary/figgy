# frozen_string_literal: true
Rails.application.routes.draw do
  mount HealthMonitor::Engine, at: "/"
  concern :searchable, Blacklight::Routes::Searchable.new
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  concern :iiif_search, BlacklightIiifSearch::Routes.new
  concern :exportable, Blacklight::Routes::Exportable.new

  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end

  authenticate :user do
    mount Tus::Server => "/local_file_upload"
  end

  root to: "catalog#index"

  post "/graphql", to: "graphql#execute", defaults: { format: :json }
  post "/resources/refresh_remote_metadata", to: "resources#refresh_remote_metadata", defaults: { format: :json }

  get "dashboard/fixity", to: "fixity_dashboard#show", as: "fixity_dashboard"
  get "dashboard/numismatics", to: "numismatics_dashboard#show", as: "numismatics_dashboard"

  resources :auth_tokens
  default_url_options Rails.application.config.action_mailer.default_url_options

  get "catalog/:solr_document_id/pdf", to: "catalog#pdf", as: "pdf"

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
  mount Blacklight::Engine => "/"

  resource :catalog, only: [:index], as: "catalog", path: "/catalog", controller: "catalog" do
    concerns :searchable
    concerns :range_searchable
  end

  # Keep this below the concerns :searchable or catalog controller will try to
  # serve opensearch requests as a solr document id
  resources :solr_documents, only: [:show], path: "/catalog", controller: "catalog" do
    concerns :exportable
    concerns :iiif_search
  end

  get "/downloads/:resource_id/file/:id(/:as)", to: "downloads#show", as: :download
  get "/manifests/:id/v3", to: "manifests#v3", as: :manifest_v3, defaults: { format: :json }
  get "/tilemetadata/:id", to: "tile_metadata#metadata", as: :tile_metadata, defaults: { format: :json }
  get "/tilemetadata/:id/tilejson", to: "tile_metadata#tilejson", as: :tile_metadata_tilejson, defaults: { format: :json }

  scope "/concern" do
    resources :file_sets do
      member do
        put :derivatives
        get :text
      end
      resources :file_metadata, only: [:create, :destroy] do
        collection do
          get "new/caption", action: :new, change_set: "caption", as: :new_caption
        end
      end
    end
    resources :scanned_resources do
      member do
        get :file_manager
        get :order_manager
        get :structure
        get :struct_manager
        get :manifest, defaults: { format: :json }
        post :server_upload
        get :pdf
      end
      collection do
        get "new/simple", action: :new, change_set: "simple", as: :new_simple
        get "new/recording", action: :new, change_set: "recording", as: :new_recording
        get "new/letter", action: :new, change_set: "letter", as: :new_letter
        get "new/cdl_resource", action: :new, change_set: "CDL::Resource", as: :new_cdl_resource
      end
      collection do
        get "save_and_ingest/:id", action: :save_and_ingest, constraints: { id: /[^\/]+/ }, defaults: { format: :json }
      end
    end
    resources :recordings do
      member do
        get :manifest, defaults: { format: :json }
      end
    end
    resources :proxy_file_sets

    resources :playlists do
      member do
        get :order_manager
        get :structure
        get :struct_manager
        get :file_manager
        get :manifest, defaults: { format: :json }
      end
    end

    # Added for redirects for IIIF Manifests.
    resources :multi_volume_works, controller: "scanned_resources", only: [] do
      member do
        get :manifest, defaults: { format: :json }
      end
    end

    get "/scanned_resources/:parent_id/new", to: "scanned_resources#new", as: :parent_new_scanned_resource

    namespace :numismatics do
      resources :accessions
      resources :coins do
        member do
          get :file_manager
          get :order_manager
          get :manifest, defaults: { format: :json }
          get :orangelight, defaults: { format: :json }
          post :server_upload
          get :discover_files
          post :auto_ingest
          get :pdf
        end
      end
      resources :issues do
        member do
          get :order_manager
          get :manifest, defaults: { format: :json }
          post :server_upload
        end
      end
      resources :finds
      resources :firms
      resources :people
      resources :places
      resources :monograms do
        member do
          get :file_manager
          get :order_manager
          get :manifest, defaults: { format: :json }
          post :server_upload
        end
      end
      resources :references
    end

    get "/numismatics/issues/:parent_id/coin" => "numismatics/coins#new", as: :parent_new_numismatics_coin
    get "/numismatics/references/:parent_id/new", to: "numismatics/references#new", as: :parent_new_numismatics_reference

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
        post :server_upload
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
        post :server_upload
      end
    end
    get "/scanned_maps/:parent_id/new", to: "scanned_maps#new", as: :parent_new_scanned_map
    put "/scanned_maps/:id/extract_metadata/:file_set_id", to: "scanned_maps#extract_metadata", as: :scanned_maps_extract_metadata
    patch "/scanned_maps/:id/remove_from_parent", to: "scanned_maps#remove_from_parent", as: :scanned_maps_remove_from_parent, defaults: { format: :json }

    resources :vector_resources do
      member do
        get :file_manager
        get :geoblacklight, defaults: { format: :json }
        post :server_upload
      end
    end
    get "/vector_resources/:parent_id/new", to: "vector_resources#new", as: :parent_new_vector_resource
    put "/vector_resources/:id/extract_metadata/:file_set_id", to: "vector_resources#extract_metadata", as: :vector_resources_extract_metadata
    patch "/vector_resources/:id/remove_from_parent", to: "vector_resources#remove_from_parent", as: :vector_resources_remove_from_parent, defaults: { format: :json }

    resources :raster_resources do
      member do
        get :file_manager
        get :geoblacklight, defaults: { format: :json }
        post :server_upload
      end
    end
    get "/raster_resources/:parent_id/new", to: "raster_resources#new", as: :parent_new_raster_resource
    put "/raster_resources/:id/extract_metadata/:file_set_id", to: "raster_resources#extract_metadata", as: :raster_resources_extract_metadata
    patch "/raster_resources/:id/remove_from_parent", to: "raster_resources#remove_from_parent", as: :raster_resources_remove_from_parent, defaults: { format: :json }
  end

  resources :collections do
    member do
      get :manifest, defaults: { format: :json }
    end
    collection do
      get "new/archival_media_collection", action: :new, change_set: "archival_media_collection", as: :new_archival_media_collection
    end
  end
  get "/iiif/collections", defaults: { format: :json }, to: "collections#index_manifest", as: :index_manifest
  get "collections/:id/ark_report", to: "collections#ark_report", as: :collections_ark_report

  get "/iiif/lookup/:prefix/:naan/:arkid", to: "catalog#lookup_manifest", as: :lookup_manifest

  get "/reports/pulfa_ark_report/(:since_date)", to: "reports#pulfa_ark_report", as: :pulfa_ark_report
  get "/reports/ephemera_data/(:project_id)", to: "reports#ephemera_data", as: :ephemera_data
  get "/reports/identifiers_to_reconcile", to: "reports#identifiers_to_reconcile", as: :identifiers_to_reconcile
  get "/reports/collection_item_and_image_count", to: "reports#collection_item_and_image_count", as: :collection_item_and_image_count

  get "bulk_ingest/:resource_type", to: "bulk_ingest#show", as: "bulk_ingest_show"
  post "bulk_ingest/:resource_type/bulk_ingest", to: "bulk_ingest#bulk_ingest", as: "bulk_ingest"

  get "bulk_edit", to: "bulk_edit#resources_edit", as: "bulk_edit_resources_edit"
  post "bulk_edit(/:batch_size)", to: "bulk_edit#resources_update", as: "bulk_edit_resources_update"
  get "bulk_edit", to: "bulk_edit#index"

  if Rails.env.development? || Rails.env.test?
    mount Riiif::Engine => "/image-service", as: "riiif"
  end

  require "sidekiq/pro/web"
  authenticate :user do
    mount Sidekiq::Web => "/sidekiq"
  end

  get "/viewer/config/:id", to: "application#viewer_config", as: "viewer_config"
  get "/viewer/exhibit/config", to: "application#viewer_exhibit_config", as: "viewer_exhibit_config"

  match "oai", to: "oai#index", via: [:get, :post]

  resources :ocr_requests, only: [:index, :destroy, :show]
  post "/ocr_requests/upload_file", to: "ocr_requests#upload_file", as: :upload_file

  resources :viewer, only: [:index] do
    member do
      get :auth
    end
  end

  resources :cdl, controller: "cdl/cdl", only: [] do
    member do
      get :status, defaults: { format: :json }
      post :charge
      post :hold
      post :return
    end
  end

  resources :deletion_markers, only: [:show, :destroy] do
    member do
      get :restore
    end
  end

  namespace :file_browser do
    resources :disk, only: [:index, :show], id: /([^\/])+?/
  end
end
