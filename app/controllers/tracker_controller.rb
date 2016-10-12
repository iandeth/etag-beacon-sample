class TrackerController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    expires_in 1.day, :public => true
    headers['ETag'] = "Wooo"
    render :js => %q|alert("hello2");|
  end

  private
  #def caching_allowed?
  #  false
  #end
end

