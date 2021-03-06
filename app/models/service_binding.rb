require 'conjur_client'

class ServiceBinding

  class RoleAlreadyCreated < RuntimeError
  end

  class HostNotFound < RuntimeError
  end

  class << self
    def create(instance_id, binding_id, app_id)
      ServiceBinding.new(instance_id, binding_id).create(app_id)
    end

    def delete(instance_id, binding_id)
      ServiceBinding.new(instance_id, binding_id).delete
    end
  end

  def initialize(instance_id, binding_id)
    @instance_id = instance_id
    @binding_id = binding_id
  end

  def create(app_id)
    host = conjur_api.role(role_name)

    raise RoleAlreadyCreated.new("Host identity already exists.") if host.exists?

    api_key = (ConjurClient.version == 4 ? create_host_v4 : create_host_v5)

    return {
      account: ConjurClient.account,
      appliance_url: ConjurClient.appliance_url,
      authn_login: "host/#{host_id}",
      authn_api_key: api_key,
      ssl_certificate: ConjurClient.ssl_cert || "",
      version: ConjurClient.version
    }
  end

  def delete
    host = conjur_api.role(role_name)

    raise HostNotFound if !host.exists?

    host.rotate_api_key

    if ConjurClient.version == 5
      load_policy template_delete, method: Conjur::API::POLICY_METHOD_PATCH
    end
  end

  private

  def create_host_v4
    hf_token =
      conjur_api.
        resource(URI::encode(ConjurClient.v4_host_factory_id, "/")).
        create_token(Time.now + 1.hour)

    options =
      if ConjurClient.platform.to_s.empty?
        {}
      else
        { annotations: { "#{ConjurClient.platform}": "true" } }
      end

    host = Conjur::API.host_factory_create_host(hf_token, host_id, options)

    host.api_key
  end

  def create_host_v5
    result = load_policy(template_create)
    result.created_roles.values.first['api_key']
  end

  def template_create
    if ConjurClient.platform.to_s.empty?
      """
      - !host #{@binding_id}
      """
    else
      """
      - !host
        id: #{@binding_id}
        annotations:
          #{ConjurClient.platform}: true
      """
    end
  end

  def template_delete
    """
    - !delete
      record: !host #{@binding_id}
    """
  end

  def load_policy(policy, method: Conjur::API::POLICY_METHOD_POST)
    conjur_api.load_policy(ConjurClient.policy, policy, method: method)
  end

  def host_id
    if ConjurClient.policy != 'root'
      "#{ConjurClient.policy}/#{@binding_id}"
    else
      @binding_id
    end
  end

  def role_name
    "#{ConjurClient.account}:host:#{host_id}"
  end

  def conjur_api
    ConjurClient.api
  end
end
