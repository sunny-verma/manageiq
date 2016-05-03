# TODO: Separate collection from parsing (perhaps collecting in parallel a la RHEVM)

module ManageIQ::Providers
  class Nuage::NetworkManager::RefreshParser
    include ManageIQ::Providers::Nuage::RefreshParserCommon::HelperMethods

    def self.ems_inv_to_hashes(ems, options = nil)
      new(ems, options).ems_inv_to_hashes
    end

    def initialize(ems, options = nil)
      @ems               = ems
      @vsd_client        = ems.connect
      @options           = options || {}
      @data              = {}
      @data_index        = {}
    end

    # TODO Define "validate_required_services" later

    def ems_inv_to_hashes
      log_header = "MIQ(#{self.class.name}.#{__method__}) Collecting data for EMS name: [#{@ems.name}] id: [#{@ems.id}]"

      get_networks
      get_subnets

      @data
    end

    private

    def get_networks
      return unless @network_service.name == :neutron

      process_collection(networks, :cloud_networks) { |n| parse_network(n) }
      get_subnets
    end
    
    def get_subnets
      subnets = @vsd_client.get_subnets
      process_collection(subnets, :cloud_subnets) {|s| parse_subnets(s)}
    end

    def to_cidr (netmask)
      '/' + netmask.to_i.to_s(2).count("1").to_s
    end

    def parse_network(network)
      uid     = network.id
      status  = (network.status.to_s.downcase == "active") ? "active" : "inactive"

      network_type_suffix = network.router_external ? "::Public" : "::Private"

      new_result = {
        :type                      => self.class.cloud_network_type + network_type_suffix,
        :name                      => network.name,
        :ems_ref                   => uid,
        :shared                    => network.shared,
        :status                    => status,
        :enabled                   => network.admin_state_up,
        :external_facing           => network.router_external,
        :cloud_tenant              => parent_manager_fetch_path(:cloud_tenants, network.tenant_id),
        :orchestration_stack       => parent_manager_fetch_path(:orchestration_stacks, @resource_to_stack[uid]),
        :provider_physical_network => network.provider_physical_network,
        :provider_network_type     => network.provider_network_type,
        :provider_segmentation_id  => network.provider_segmentation_id,
        :vlan_transparent          => network.attributes["vlan_transparent"],
        # TODO(lsmola) expose attributes in FOG
        :maximum_transmission_unit => network.attributes["mtu"],
        :port_security_enabled     => network.attributes["port_security_enabled"],
      }
      return uid, new_result
    end
    
    def parse_subnets(subnet)
      uid = subnet['ID']

      new_result = {
        :type                           => self.class.cloud_subnet_type,
        :name                           => subnet['name'],
        :ems_ref                        => uid,
        :cidr                           => subnet['address'] + to_cidr(subnet['netmask']),
        :network_protocol               => subnet['IPType'].downcase!,
        :gateway                        => subnet['gateway'],
        :dhcp_enabled                   => false,
        :ip_version                     => 4,
      }
      return uid, new_result
    end

    class << self
      def cloud_subnet_type
        "ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet"
      end
    end
  end
end
