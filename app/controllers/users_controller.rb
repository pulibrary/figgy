# frozen_string_literal: true

class UsersController < ApplicationController
  def index
    authorize! :manage, User.new
    @users = User.all.order(:uid)
  end

  def create
    authorize! :manage, User.new
    User.create!(user_params)
    respond_to do |format|
      format.html { redirect_to users_url, notice: "User was successfully created." }
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_to users_url, notice: "Error creating user: #{e.message}" }
    end
  end

  def destroy
    @user = User.find(params[:id])
    authorize! :delete, @user
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: "User was successfully destroyed." }
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:uid).merge(provider: "cas", email: "#{params[:user][:uid]}@princeton.edu")
    end
end
