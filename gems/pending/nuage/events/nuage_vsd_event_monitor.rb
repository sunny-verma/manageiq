require 'nuage/nuage_event_monitor'
require 'nuage/events/nuage_event'
require 'nuage/events/nuage_vsd_event_converter'

class NuageVSDEventMonitor < NuageEventMonitor
  def self.available?(options = {})
    begin
      options[:ems].connect(:service => "Metering")
      return true
    rescue => ex
      $log.debug("Skipping Nuage VSD events. Availability check failed with #{ex}.") if $log
      raise
    end
  end

  def self.plugin_priority
    1
  end

  def initialize(options = {})
    @options = options
    @ems = options[:ems]
    @config = options.fetch(:vsd, {})
  end

  def start
    @since          = nil
    @monitor_events = true
  end

  def stop
    @monitor_events = false
  end

  def provider_connection
    @provider_connection ||= @ems.connect
  end

  def each_batch
    while @monitor_events
      $log.info("Querying Nuage VSD for events newer than #{latest_event_timestamp}...") if $log
      events = list_events(query_options).sort_by(&:generated)
      @since = events.last.generated unless events.empty?

      amqp_events = filter_unwanted_events(events).map do |event|
        converted_event = NuageVsdEventConverter.new(event)
        $log.debug("Nuage VSD is processing a new event: #{event.inspect}") if $log
        nuage_event(nil, converted_event.metadata, converted_event.payload)
      end

      yield amqp_events
    end
  end

  def each
    each_batch do |events|
      events.each { |e| yield e }
    end
  end

  private

  def filter_unwanted_events(events)
    $log.debug("Nuage VSD received a new events batch: (before filtering)") if $log && events.any?
    $log.debug(events.inspect) if $log && events.any?
    @event_type_regex ||= Regexp.new(@config[:event_types_regex].to_s)
    events.select { |event| @event_type_regex.match(event.event_type) }
  end

  def query_options
    [{
      'field' => 'start_timestamp',
      'op'    => 'ge',
      'value' => latest_event_timestamp || ''
    }]
  end

  def list_events(query_options)
    provider_connection.get_events
  end

  def latest_event_timestamp
    @since ||= @ems.ems_events.maximum(:timestamp)
  end
end

