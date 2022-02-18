# frozen_string_literal: true

class AuthTokensController < ApplicationController
  before_action :set_auth_token, only: [:show, :edit, :update, :destroy]
  authorize_resource only: [:new, :edit, :create, :update, :destroy]

  # GET /auth_tokens
  def index
    @auth_tokens = AuthToken.all
  end

  # GET /auth_tokens/1
  def show
  end

  # GET /auth_tokens/new
  def new
    @auth_token = AuthToken.new
  end

  # GET /auth_tokens/1/edit
  def edit
  end

  # POST /auth_tokens
  def create
    @auth_token = AuthToken.new(auth_token_params)

    if @auth_token.save
      redirect_to @auth_token, notice: "Auth token was successfully created."
    else
      render :new
    end
  end

  # PATCH/PUT /auth_tokens/1
  def update
    if @auth_token.update(auth_token_params)
      redirect_to @auth_token, notice: "Auth token was successfully updated."
    else
      render :edit
    end
  end

  # DELETE /auth_tokens/1
  def destroy
    @auth_token.destroy
    redirect_to auth_tokens_url, notice: "Auth token was successfully destroyed."
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_auth_token
      @auth_token = AuthToken.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def auth_token_params
      params.require(:auth_token).permit(:label, group: [])
    end
end
