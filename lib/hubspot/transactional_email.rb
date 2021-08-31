module Hubspot
  #
  # HubSpot Transactional Email API
  #
  # {https://developers.hubspot.com/docs/api/marketing/transactional-emails}
  #
  class TransactionalEmail

    CREATE_SINGLE_EMAIL_PATH = "/marketing/v3/transactional/single-email/send"
    

    attr_reader :properties
    attr_reader :event_id
    attr_reader :status_id
    attr_reader :send_result
    attr_reader :status

    def initialize(response_hash)
      @properties = response_hash
      @event_id = response_hash["eventId"]
      @status_id = response_hash["statusId"]
      @send_result = response_hash["sendResult"]
      @status = response_hash["status"]
    end

    class << self
      def create_single_email!(emailId, messageParams={}, contactPropertiesParams={}, customPropertiesParams={})
        post_data = {emailId: emailId, message: messageParams, contactProperties: contactPropertiesParams, customProperties: customPropertiesParams}
        response = Hubspot::Connection.post_json(CREATE_SINGLE_EMAIL_PATH, params: {}, body: post_data )
        new(response)
      end

    end
  end
end
