# frozen_string_literal: true

Cloudenvoy::Engine.routes.draw do
  post '/receive', to: 'subscriber#receive'
end
