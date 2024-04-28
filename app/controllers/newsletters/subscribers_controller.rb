class Newsletters::SubscribersController < ApplicationController
  layout "newsletters"

  before_action :ensure_authenticated, only: [ :index ]
  before_action :set_newsletter, only: [ :index ]
  skip_before_action :verify_authenticity_token, only: [ :embed_subscribe ]


  def index
    page = params[:page] || 0
    status = params[:status] || "verified"

    @subscribers = @newsletter.subscribers
      .order(created_at: :desc)
      .page(page || 0)
      .where(status: status)
      .per(30)
  end

  def embed_subscribe
    subscriber = subscribe
    subscriber.update(created_via: "embed")
  end

  def subscribe
    name = params[:name]
    email = params[:email]
    @newsletter = Newsletter.from_slug(params[:slug])

    subscriber = @newsletter.subscribers.create(
      email: email,
      full_name: name
    )

    subscriber.send_confirmation_email
    subscriber
  end

  def unsubscribe
    token = params[:token]
    @newsletter = Newsletter.from_slug(params[:slug])

    decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: "HS256" })
    subscriber_id = decoded_token.first["sub"]
    subscriber = @newsletter.subscribers.find(subscriber_id)
    subscriber.unsubscribe!
    # Log the unsubscribe activity
    Rails.logger.info("Subscriber #{subscriber.id} unsubscribed from newsletter #{@newsletter.id}")
    # if request is a get, render the layout, or respond with 200 and json ok if it is a post
    if request.post?
      render json: { ok: true }
    else
      render :unsubscribed, layout: "application"
    end
  rescue JWT::ExpiredSignature, JWT::DecodeError, ActiveRecord::RecordNotFound
    render :invalid, layout: "application"
  end

  private

  def set_newsletter
    @newsletter = Current.user.newsletters.from_slug(params[:slug])
    redirect_to newsletter_url(Current.user.newsletters.first.slug) unless @newsletter
  end
end
