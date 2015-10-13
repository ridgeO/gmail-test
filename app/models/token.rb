
require 'net/http'
require 'json'

class Token < ActiveRecord::Base

  class << self

    def from_omniauth(auth_hash)
      token = find_or_create_by(uid: auth_hash["uid"])
      token.access_token = auth_hash["credentials"]["token"]
      token.refresh_token = auth_hash["credentials"]["refresh_token"]
      token.expires_at = auth_hash["credentials"]["expires_at"]
      token.save!
      token
    end

  end

  def to_params
    {'refresh_token' => refresh_token,
    'client_id' => ENV['CLIENT_ID'],
    'client_secret' => ENV['CLIENT_SECRET'],
    'grant_type' => 'refresh_token'}
  end

  def request_token_from_google
    url = URI("https://www.googleapis.com/oauth2/v3/token")
    Net::HTTP.post_form(url, self.to_params)
  end

  def refresh!
    response = request_token_from_google
    data = JSON.parse(response.body)
    update_attributes(
    access_token: data['access_token'],
    expires_at: Time.now + (data['expires_in'].to_i).seconds)
  end

  def expired?
    expires_at < Time.now
  end

  def fresh_token
    refresh! if expired?
    access_token
  end

end
