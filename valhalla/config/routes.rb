# frozen_string_literal: true
Valhalla::Engine.routes.draw do
  get '/downloads/:resource_id/file/:id', to: 'downloads#show', as: :download
end
