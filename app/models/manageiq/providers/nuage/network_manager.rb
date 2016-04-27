class ManageIQ::Providers::Nuage::NetworkManager < ManageIQ::Providers::NetworkManager
  require_nested :RefreshParser
  require_nested :RefreshWorker
  require_nested :Refresher
  require_nested :VsdClient

  def self.raw_connect(auth_url, username, password)

    VsdClient.new(auth_url, username, password)

  end

  def connect(options = {})
    raise "no credentials defined" if self.missing_credentials?(options[:auth_type])

    protocol = options[:protocol]
    server   = options[:ip] || address
    port     = options[:port] || self.port
    username = options[:user] || authentication_userid(options[:auth_type])
    password = options[:pass] || authentication_password(options[:auth_type])
    version  = options[:version] || api_version

    self.class.raw_connect(auth_url(protocol, server, port ,version), username, password)
  end

  def auth_url(protocol, server, port, version)
    return protocol+'://' + server + ':' + port + '/' + 'nuage/api/' + version
  end

end
