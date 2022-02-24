module Hubspot
  #
  # HubSpot Tickets API
  #
  # {https://developers.hubspot.com/docs/api/crm/tickets}
  #
  class Ticket
    TICKETS_PATH = '/crm/v3/objects/tickets'
    TICKET_PATH  = '/crm/v3/objects/tickets/:id'

    attr_reader :id, :properties, :archived

    def initialize(response_hash)
      @id = response_hash['id']
      @properties = response_hash['properties']
      @archived = response_hash['archived']
    end

    class << self

      def create!(properties={})
        response = Hubspot::Connection.post_json(TICKETS_PATH, params: {}, body: properties )
        new(response)
      end

      def find(id, properties={})
        options = {
          id: id,
          properties: properties
        }
        response = Hubspot::Connection.get_json(TICKET_PATH , options)
        new(response)
      end

    end
  end
end
