# Taken from https://github.com/captaincontrat/hubspot-api-ruby/blob/master/lib/hubspot/association.rb
class Hubspot::Association
  CONTACT_TO_COMPANY = 1
  COMPANY_TO_CONTACT = 2
  CONTACT_TO_COMPANY_V2 = 279
  COMPANY_TO_CONTACT_V2 = 280
  DEAL_TO_CONTACT = 3
  CONTACT_TO_DEAL = 4
  DEAL_TO_COMPANY = 5
  COMPANY_TO_DEAL = 6
  CONTACT_TO_ENGAGEMENT = 9
  ENGAGEMENT_TO_CONTACT = 10
  PARENT_COMPANY_TO_CHILD_COMPANY = 13
  CHILD_COMPANY_TO_PARENT_COMPANY = 14
  TICKET_TO_CONTACT = 16
  TICKET_TO_COMPANY = 26

  DEFINITION_TARGET_TO_CLASS = {
    Hubspot::Company    => [1, 5, 13, 14, 279],
    Hubspot::Contact    => [2, 3, 10, 280],
    Hubspot::Deal       => [4, 6],
    Hubspot::Engagement => [9],
  }.freeze

  BATCH_CREATE_PATH = '/crm-associations/v1/associations/create-batch'
  BATCH_DELETE_PATH = '/crm-associations/v1/associations/delete-batch'
  ASSOCIATIONS_PATH = '/crm-associations/v1/associations/:resource_id/HUBSPOT_DEFINED/:definition_id'
  BATCH_CREATE_V2_PATH = '/crm/v3/associations/:fromObjectType/:toObjectType/batch/create'
  BATCH_DELETE_V2_PATH = '/crm/v3/associations/:fromObjectType/:toObjectType/batch/archive'
  TYPES_PATH = '/crm/v3/associations/:fromObjectType/:toObjectType/types'

  class << self
    def create(from_id, to_id, definition_id)
      raise(Hubspot::InvalidParams, 'Definition not supported') if definition_id > 100
      batch_create([{ from_id: from_id, to_id: to_id, definition_id: definition_id }])
    end

    # Make multiple associations in a single API call
    # {https://developers.hubspot.com/docs/methods/crm-associations/batch-associate-objects}
    # usage:
    # Hubspot::Association.batch_create([{ from_id: 1, to_id: 2, definition_id: Hubspot::Association::COMPANY_TO_CONTACT }])
    def batch_create(associations)
      request = associations.map { |assocation| build_association_body(assocation) }
      Hubspot::Connection.put_json(BATCH_CREATE_PATH, params: { no_parse: true }, body: request)
    end
    
    # See: https://developers.hubspot.com/docs/api/crm/associations
    def batch_create_v2(associations, from_type, to_type)
      request = { inputs: associations.map { |assocation| build_association_body_v2(assocation) } }
      Hubspot::Connection.post_json(BATCH_CREATE_V2_PATH, params: { fromObjectType: from_type, toObjectType: to_type }, body: request)
    end

    def delete(from_id, to_id, definition_id)
      batch_delete([{from_id: from_id, to_id: to_id, definition_id: definition_id}])
    end

    # Remove multiple associations in a single API call
    # {https://developers.hubspot.com/docs/methods/crm-associations/batch-delete-associations}
    # usage:
    # Hubspot::Association.batch_delete([{ from_id: 1, to_id: 2, definition_id: Hubspot::Association::COMPANY_TO_CONTACT }])
    def batch_delete(associations)
      request = associations.map { |assocation| build_association_body(assocation) }
      Hubspot::Connection.put_json(BATCH_DELETE_PATH, params: { no_parse: true }, body: request)
    end

    # See: https://developers.hubspot.com/docs/api/crm/associations
    def batch_delete_v2(associations, from_type, to_type)
      request = { inputs: associations.map { |assocation| build_association_body_v2(assocation) } }
      Hubspot::Connection.post_json(BATCH_DELETE_V2_PATH, params: { fromObjectType: from_type, toObjectType: to_type }, body: request)
    end

    # Retrieve all associated resources given a source (resource_id) and a kind (definition_id)
    # Example: if resource_id is a deal, using DEAL_TO_CONTACT will find every contact associated with the deal
    # {https://developers.hubspot.com/docs/methods/crm-associations/get-associations}
    # Warning: it will make N+M queries, where
    #   N is the number of PagedCollection requests necessary to get all ids,
    #   and M is the number of results, each resulting in a find
    # usage:
    # Hubspot::Association.all(42, Hubspot::Association::DEAL_TO_CONTACT)
    def all(resource_id, definition_id, options={})
      opts = { resource_id: resource_id, definition_id: definition_id }
      klass = DEFINITION_TARGET_TO_CLASS.find{ |k,v| definition_id.in?(v) ? k : nil }&.first
      raise(Hubspot::InvalidParams, 'Definition not supported') unless klass.present?

      params = opts.merge( options.slice(:offset, :limit) )
      dont_expand = options.fetch(:dont_expand, false)
      response = Hubspot::Connection.get_json(ASSOCIATIONS_PATH, params)
      unless dont_expand
        result = {}
        finder = klass.respond_to?(:find_by_id) ? :find_by_id : :find
        result['associations'] = response['results'].map { |result| klass.send(finder, result) }
        result['offset'] = response['offset']
        result['hasMore'] = response['hasMore']
        result
      else
        response
      end
    end

    # See: https://developers.hubspot.com/docs/api/crm/associations
    def types(from_type, to_type)
      Hubspot::Connection.get_json(TYPES_PATH, {fromObjectType: from_type, toObjectType: to_type})
    end

    private

    def build_association_body(assocation)
      {
        fromObjectId: assocation[:from_id],
        toObjectId: assocation[:to_id],
        category: 'HUBSPOT_DEFINED',
        definitionId: assocation[:definition_id]
      }
    end

    def build_association_body_v2(assocation)
      {
        from: { id: assocation[:from_id] },
        to:   { id: assocation[:to_id] },
        type: assocation[:type]
      }
    end
  end
end