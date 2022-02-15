require 'logger'
require 'hubspot/connection'

module Hubspot
  class Config
    CONFIG_KEYS = [
      :hapikey, :base_url, :portal_id, :logger, :access_token, :client_id,
      :client_secret, :redirect_uri, :read_timeout, :open_timeout
    ]
    DEFAULT_LOGGER = Logger.new(nil)
    DEFAULT_BASE_URL = "https://api.hubapi.com".freeze

    class << self
      CONFIG_KEYS.each do |key|
        define_method(key) { Thread.current["hubspot_config_#{key}"] }
        define_method("#{key}=") do |value|
          Thread.current["hubspot_config_#{key}"] = value
        end
      end

      def configure(config)
        config.stringify_keys!
        self.hapikey = config["hapikey"]
        self.base_url = config["base_url"] || DEFAULT_BASE_URL
        self.portal_id = config["portal_id"]
        self.logger = config["logger"] || DEFAULT_LOGGER
        self.access_token = config["access_token"]
        self.client_id = config["client_id"] if config["client_id"].present?
        self.client_secret = config["client_secret"] if config["client_secret"].present?
        self.redirect_uri = config["redirect_uri"] if config["redirect_uri"].present?
        self.read_timeout = config['read_timeout'] || config['timeout']
        self.open_timeout = config['open_timeout'] || config['timeout']

        unless authentication_uncertain?
          raise Hubspot::ConfigurationError.new("You must provide either an access_token or an hapikey")
        end

        if access_token.present?
          Hubspot::Connection.headers("Authorization" => "Bearer #{access_token}")
        end
        self
      end

      def reset!
        self.hapikey = nil
        self.base_url = DEFAULT_BASE_URL
        self.portal_id = nil
        self.logger = DEFAULT_LOGGER
        self.access_token = nil
        Hubspot::Connection.headers({})
      end

      def ensure!(*params)
        params.each do |p|
          raise Hubspot::ConfigurationError.new("'#{p}' not configured") unless send(p)
        end
      end

      private

      def authentication_uncertain?
        access_token.present? ^ hapikey.present?
      end
    end

    reset!
  end
end
