require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /coming_soon" do
    it "returns http success" do
      get "/pages/coming_soon"
      expect(response).to have_http_status(:success)
    end
  end

end
