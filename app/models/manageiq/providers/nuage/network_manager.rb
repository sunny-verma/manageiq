Class ManageIQ::Providers::Nuage::NetworkManager < ManageIQ::Providers::NetworkManager
  require_nested :RefreshParser
  require_nested :RefreshWorker
  require_nested :Refresher

  def self.ems_type
    @ems_type ||= "nuage".freeze
  end

  def self.description
    @description ||= "Nuage Networks".freeze
  end

end
