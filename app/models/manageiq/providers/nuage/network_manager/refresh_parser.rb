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
      get_network_routers

      @data
    end

    private

    def get_networks
      networks = ['1'];
      process_collection(networks, :cloud_networks) { |n| parse_network(n) }
      get_subnets
    end
    
    def get_network_routers
      network_routers = ['1'];
      process_collection(network_routers, :network_routers) { |n| parse_network_router(n) }
    end
    
    def get_subnets
      #subnets = @vsd_client.get_subnets
      #process_collection(subnets, :cloud_subnets) {|s| parse_subnets(s)}
      networks = ['1'];
      networks.each do |n|
        #new_net = @data_index.fetch_path(:cloud_networks, 1)
        new_net = Hash.new
        new_net[:cloud_subnets] = @vsd_client.get_subnets.collect { |s| parse_subnets(s) }

        # Lets store also subnets into indexed data, so we can reference them elsewhere
        #new_net[:cloud_subnets].each do |x|
          #@data_index.store_path(:cloud_subnets, x[:ems_ref], x)
          #@data[:cloud_subnets] << x
        #end
      end
    end

    def to_cidr (netmask)
      '/' + netmask.to_i.to_s(2).count("1").to_s
    end

    def parse_network(network)
      uid     = 1
      status  = "active"

      network_type_suffix = "::Public" 

      new_result = {
        :type                      => self.class.cloud_network_type + network_type_suffix,
        :name                      => "Nuage Network",
        :ems_ref                   => "1",
        :shared                    => "shared",
        :status                    => "status",
        :enabled                   => "enabled",
        :external_facing           => "ef",
        :cloud_tenant              => parent_manager_fetch_path(:cloud_tenants, 5),
        :orchestration_stack       => parent_manager_fetch_path(:orchestration_stacks, @resource_to_stack[uid]),
        :provider_physical_network => "ppn",
        :provider_network_type     => "pnt",
        :provider_segmentation_id  =>  342,
        :vlan_transparent          => "vt",
        :maximum_transmission_unit => "mtu",
        :port_security_enabled     => "pse",
      }
      return uid, new_result
    end
    
    def parse_network_router(network_router)
      uid        = 2
      network_id = 3
      new_result = {
        :type                  => self.class.network_router_type,
        :name                  => "nuage Router",
        :ems_ref               => "2",
        :cloud_network         => @data_index.fetch_path(:cloud_networks, network_id),
        :admin_state_up        => "asu",
        :cloud_tenant          => nil,
        :status                => "s",
        :external_gateway_info => "emi",
        :distributed           => "d",
        :routes                => "r",
        :high_availability     => "ha",
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
    
    def parent_manager_fetch_path(collection, ems_ref)
      @parent_manager_data ||= {}
      return @parent_manager_data.fetch_path(collection, ems_ref) if @parent_manager_data.has_key_path?(collection, ems_ref)

      @parent_manager_data.store_path(collection, ems_ref, @ems.public_send(collection).try(:where, :ems_ref => ems_ref).try(:first))
    end

    class << self
      def cloud_network_type
        "ManageIQ::Providers::Nuage::NetworkManager::CloudNetwork"
      end
      def network_router_type
        "ManageIQ::Providers::Nuage::NetworkManager::NetworkRouter"
      end
      def cloud_subnet_type
        "ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet"
      end
    end
  end
end
