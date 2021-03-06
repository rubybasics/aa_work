class SessionsController < ApplicationController
  skip_before_filter :require_login, only: [:new, :create]
  def new
    render :new
  end

  def create
    @user = User.find_by_credentials(params[:user][:user_name],                                                      params[:user][:password])

    if @user.nil?
      flash[:errors] = ["Credentials were wrong"]
      render :new
    else
      self.current_user = @user
      redirect_to cats_url
    end
  end

  def destroy
    Session.find_by_session_token(session[:session_token]).delete
    session[:session_token] = nil
    redirect_to new_session_url
  end
end
