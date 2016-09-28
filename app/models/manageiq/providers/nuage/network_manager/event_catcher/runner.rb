class ManageIQ::Providers::Nuage::NetworkManager::EventCatcher::Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
  include ManageIQ::Providers::Nuage::EventCatcherMixin

  def add_nuage_queue(event_hash)
    EmsEvent.add_queue('add_nuage_network', @cfg[:ems_id], event_hash)
  end
end
