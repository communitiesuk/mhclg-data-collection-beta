require "configuration/configuration_service"
require "configuration/paas_configuration_service"
require "configuration/env_configuration_service"
require Rails.root.join("app/helpers/platform_helper")

configuration_service = PlatformHelper.is_paas? ? Configuration::PaasConfigurationService.new : Configuration::EnvConfigurationService.new

if Rails.env.development? || Rails.env.test?
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  Rack::Attack.enabled = false
elsif Rails.env.review?
  redis_url = configuration_service.redis_uris.to_a[0][1]
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: redis_url)
else
  redis_url = PlatformHelper.is_paas? ? configuration_service.redis_uris[:"dluhc-core-#{Rails.env}-redis"] : configuration_service.redis_uris.to_a[0][1]
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: redis_url)
end

Rack::Attack.throttle("password reset requests", limit: 5, period: 60.seconds) do |request|
  if request.params["user"].present? && request.path == user_password_path && request.post?
    request.params["user"]["email"].to_s.downcase.gsub(/\s+/, "")
  end
end

Rack::Attack.throttle("admin password reset requests", limit: 5, period: 60.seconds) do |request|
  if request.params["admin_user"].present? && request.path == "/admin/password" && request.post?
    request.params["admin_user"]["email"].to_s.downcase.gsub(/\s+/, "")
  end
end

Rack::Attack.throttled_responder = lambda do |_env|
  headers = {
    "Location" => "/429",
  }
  [301, headers, []]
end
