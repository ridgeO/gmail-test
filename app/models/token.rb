
require 'net/http'
require 'json'

class Token < ActiveRecord::Base

  def to_params
    {'code' => authorization_code,
    'client_id' => ENV['CLIENT_ID'],
    'client_secret' => ENV['CLIENT_SECRET'],
    'redirect_uri' => 'redirect_uri',
    'grant_type' => 'authorization_code'}
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
    refresh_token: data['refresh_token'],
    expires_at: Time.now + (data['expires_in'].to_i).seconds)
  end

  def expired?
    expires_at < Time.now
  end

  def fresh_token
    refresh! if expired?
    access_token
  end

  class << self

    def first_round(auth_hash)
      token = find_or_create_by(uid: auth_hash["uid"])
      token.authorization_code = request['code']
      token.save!
      token.fresh_token
    end

  end

end
