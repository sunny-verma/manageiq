Class ManageIQ::Providers::Nuage::NetworkManager < ManageIQ::Providers::NetworkManager
  require_nested :RefreshParser
  require_nested :RefreshWorker
  require_nested :Refresher


end
