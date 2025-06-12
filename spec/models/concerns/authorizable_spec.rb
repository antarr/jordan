require 'rails_helper'

RSpec.describe Authorizable, type: :concern do
  let(:authorizable_instance) { create(:user, :complete_registration) }

  it_behaves_like 'authorizable'
end
