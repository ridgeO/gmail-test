class User < ActiveRecord::Base

  require 'net/http'
  require 'json'

  class << self

    def from_omniauth(auth_hash)
      user = find_or_create_by(uid: auth_hash["uid"], provider: auth_hash['provider'])
      user.name = auth_hash["info"]["name"]
      user.location = auth_hash["info"]["location"]
      user.image_url = auth_hash["info"]["image"]
      user.url = auth_hash["info"]["urls"][user.provider.capitalize]
      user.access_token = auth_hash["credentials"]["token"]
      user.refresh_token = auth_hash["credentials"]["refresh_token"]
      user.expires_at = Time.at(auth_hash["credentials"]["expires_at"]).to_datetime
      user.save!
      user
    end

  end

  def to_params(user)
    {'refresh_token' => user.refresh_token,
    'client_id' => ENV['CLIENT_ID'],
    'client_secret' => ENV['CLIENT_SECRET'],
    'grant_type' => 'refresh_token'}
  end

  def request_token_from_google
    url = URI("https://accounts.google.com/o/oauth2/token")
    Net::HTTP.post_form(url, self.to_params)
  end

  def refresh!(user)
    response = request_token_from_google
    data = JSON.parse(response.body)
    user.update_attributes(
    access_token: data['access_token'],
    expires_at: Time.now + (data['expires_in'].to_i).seconds)
  end

  def expired?(user)
    user.expires_at < Time.now
  end

  def fresh_token(user)
    user.refresh! if user.expired?
    access_token
  end

end
