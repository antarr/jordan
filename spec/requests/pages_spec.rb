require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /coming-soon" do
    it "returns http success" do
      get "/coming-soon"
      expect(response).to have_http_status(:success)
    end
  end
  
  describe "GET /" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end
  end

end
