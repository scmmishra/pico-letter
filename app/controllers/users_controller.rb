class UsersController < ApplicationController
  before_action :resume_session_if_present, only: [ :new, :verify ]
  before_action :set_require_invite_code, only: [ :new, :create ]
  before_action :check_invite_code, only: [ :create ]

  def new
    if Current.user.present?
      redirect_to_newsletter_home
    else
      render :new
    end
  end

  def create
    @user = User.new(user_params.except(:invite_code))

    if @user.save
      start_new_session_for @user
      @user.send_verification_email
      redirect_to_newsletter_home
    else
      redirect_to signup_url, notice: error_messages_for(@user.errors)
    end
  end

  def verify
    @user = User.find_by_token_for(:verification, params[:token])

    if @user
      start_new_session_for @user
      redirect_to_newsletter_home
    else
      redirect_to login_url, notice: "Invalid verification token"
    end
  end

  private

  def check_invite_code
    return unless @require_invite

    if user_params[:invite_code].blank?
      redirect_to signup_url, notice: "Please enter an invite code."
    elsif user_params[:invite_code] != AppConfig.get("INVITE_CODE")
      redirect_to signup_url, notice: "Invalid invite code"
    end
  end

  def set_require_invite_code
    @require_invite = AppConfig.get("INVITE_CODE").present?
  end

  def user_params
    params.permit(:email, :password, :name, :invite_code)
  end

  def verify_params
    params.permit(:token)
  end

  def error_messages_for(errors)
    first = errors.first
    return "Something went wrong. Please try again." if first.attribute == :email && first.type == :taken

    errors.full_messages.to_sentence
  end
end
