# frozen_string_literal: true

# Authentication test helpers
module AuthTestHelpers
  AUTH_HEADER_NAME = 'HTTP_AUTHORIZATION'.freeze

  def included(m)
    after(:each) { eject_authorization! }
  end

  def inject_authorization!(m)
    @request.headers[AUTH_HEADER_NAME] = "Bearer #{jwt_for(m)}"
  end

  def eject_authorization!
    @request.headers[AUTH_HEADER_NAME] = nil
  end
end

RSpec.configure do |config|
  config.include AuthTestHelpers, type: :controller
end
