require "rails_helper"
require_relative "../support/devise"
require "rack/attack"

describe "Rack::Attack" do
  let(:limit) { 5 }
  let(:under_limit) { limit / 2 }
  let(:over_limit) { limit + 1 }

  let(:page) { Capybara::Node::Simple.new(response.body) }
  let(:notify_client) { instance_double(Notifications::Client) }
  let(:devise_notify_mailer) { DeviseNotifyMailer.new }

  let(:params) { { user: { email: } } }
  let(:admin_params) { { admin_user: { email: admin_email } } }
  let(:user) { FactoryBot.create(:user) }
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:email) { user.email }
  let(:admin_email) { admin_user.email }

  before do
    Rack::Attack.enabled = true
    allow(DeviseNotifyMailer).to receive(:new).and_return(devise_notify_mailer)
    allow(devise_notify_mailer).to receive(:notify_client).and_return(notify_client)
    allow(notify_client).to receive(:send_email).and_return(true)
  end

  after do
    Rack::Attack.enabled = false
    Rack::Attack.reset!
  end

  context "when a password reset is requested" do
    context "when the number of requests is under the throttle limit" do
      it "does not throttle for a regular user" do
        under_limit.times do
          post "/account/password", params: params
          follow_redirect!
        end
        last_response = response
        expect(last_response.status).to eq(200)
      end

      it "does not throttle for an admin user" do
        under_limit.times do
          post "/admin/password", params: admin_params
          follow_redirect!
        end
        last_response = response
        expect(last_response.status).to eq(200)
      end
    end

    context "when the number of requests is at the throttle limit" do
      it "does not throttle for a regular user" do
        limit.times do
          post "/account/password", params: params
          follow_redirect!
        end
        last_response = response
        expect(last_response.status).to eq(200)
      end

      it "does not throttle for an admin user" do
        limit.times do
          post "/admin/password", params: admin_params
          follow_redirect!
        end
        last_response = response
        expect(last_response.status).to eq(200)
      end

      it "does not throttle if both endpoints are hit" do
        limit.times do
          post "/account/password", params: params
          follow_redirect!
          post "/admin/password", params: admin_params
          follow_redirect!
        end
        last_response = response
        expect(last_response.status).to eq(200)
      end
    end

    context "when the number of requests is over the throttle limit" do
      it "throttles for a regular user" do
        over_limit.times do
          post "/account/password", params: params
          follow_redirect!
        end
        last_response = response
        expect(last_response.status).to eq(429)
      end

      it "throttles for an admin user" do
        over_limit.times do
          post "/admin/password", params: admin_params
          follow_redirect!
        end
        last_response = response
        expect(last_response.status).to eq(429)
      end
    end
  end
end
