require 'rest-client'
require 'rubygems'
require 'json'
module ManageIQ::Providers
  class Nuage::NetworkManager::VsdClient
    def initialize(server, user, password)
      @server=server
      @user=user
      @password=password
      @restCall = Rest.new(server, user, password);
      _is_conn, data = @restCall.login
      if _is_conn
        @enterprise_id = data
        return
      end
      p 'VSD Authentication failed'
    end

    def get_domains
      response = @restCall.get(@server + '/domains')
      if (response.code == 200)
        if (response.body == '')
          p 'No domains present'
          return
        end
        return JSON.parse(response.body)
      end
      p 'Error in connection '+response.code.to_s
    end

    def get_subnets
      response = @restCall.get(@server + '/subnets')
      if (response.code == 200)
        if (response.body == '')
          p 'No subnets present'
          return
        end
        subnets = JSON.parse(response.body)
        p subnets
        return subnets
      end
      p 'Error in connection '+response.code.to_s
    end

    def to_cidr (netmask)
      '/' + netmask.to_i.to_s(2).count("1").to_s
    end

    def get_vPorts
      response = @restCall.get(@server + '/vports')
      if (response.code == 200)
        if (response.body == '')
          p 'No vports present'
          return
        end
        return JSON.parse(response.body)
      end
      p 'Error in connection '+response.code.to_s
    end

    def get_vms
      response = @restCall.get(@server + '/vms')
      if (response.code == 200)
        if (response.body == '')
          p 'No VM present'
          return
        end
        return JSON.parse(response.body)
      end
      p 'Error in connection '+response.code.to_s
    end

    def install_license(license_str)
      licenseDict = {}
      licenseDict['license']= license_str
      response = @restCall.post(@server + '/licenses', JSON.dump(licenseDict))
      if (response.code != 201)
        if (response.body == 'The license already exists')
          p 'license install failed'
        end
      end
    end

    def add_csproot_to_cms_group
      response = @restCall.get(@server + "/enterprises/#@enterprise_id/groups")
      groups = JSON.parse(response.body)
      cms_group_id = nil
      csproot_user_id = nil

      for group in groups
        p 'group::'+group
        if group['name'] == 'CMS Group'
          cms_group_id = group['ID']
        end
      end

      response = @restCall.get(@server + "/enterprises/#@enterprise_id/users")
      users = JSON.parse(response.body)
      for user in users
        p 'user::'+user
        if user['userName'] == 'csproot'
          csproot_user_id = user['ID']
        end
      end

      response = @restCall.get(@server + "/enterprises/#@cms_group_id/users")
      p response.body
      userlist = ['{'+csproot_user_id+'}']
      response = @restCall.put(@server + "/groups/#@cms_group_id/users", JSON.dump(userlist))
      response = @restCall.get(@server + "/groups/#@cms_group_id/users")
      p response.body
    end

    class << self
      def security_group_type
        'ManageIQ::Providers::Nuage::NetworkManager::SecurityGroup'
      end

      def network_router_type
        "ManageIQ::Providers::Nuage::NetworkManager::NetworkRouter"
      end

      def cloud_network_type
        "ManageIQ::Providers::Nuage::NetworkManager::CloudNetwork"
      end

      def cloud_subnet_type
        "ManageIQ::Providers::Nuage::NetworkManager::CloudSubnet"
      end

      def floating_ip_type
        "ManageIQ::Providers::Nuage::NetworkManager::FloatingIp"
      end

      def network_port_type
        "ManageIQ::Providers::Nuage::NetworkManager::NetworkPort"
      end
    end
  end
end

