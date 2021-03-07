require_relative 'helpers'
require_relative 'slotter'

class WorkWeek

  # As day-long offsets from Sunday (e.g. 1 is Monday)
  WEEK_DAYS = [1, 2, 3, 4, 5]

  attr_reader :weeks_this_month

  def initialize(config, service, date=nil)
    @calendar_id = config['calendar_id']
    @event_name_prefix = config['event_name_prefix']


    @service = service
    time = date ? Time.parse(date) : Time.now



    @weeks_this_month = weeks_in_month(time)



    @time_zone = @service.get_calendar(@calendar_id).time_zone

    offset = TZInfo::Timezone.get(@time_zone).utc_offset
    offset_prefix = offset >= 0 ? '+' : ''
    @offset_str = "#{offset_prefix}#{offset}"


    @outer_start_time = time - time.wday * DAY
    @outer_start_time = Time.parse("#{time_datestr(@outer_start_time)}T00:00:00#{@offset_str}")
    @outer_end_time = time + (6 - time.wday) * DAY
    @outer_end_time = Time.parse("#{time_datestr(@outer_end_time)}T23:59:59#{@offset_str}")


    # "outer" includes days of the week outside the work days
    @start_time = @outer_start_time + DAY
  end

  def allocated_work
    response = @service.list_events(@calendar_id,
                                    max_results: 100,
                                    single_events: true,
                                    time_min: @outer_start_time.to_datetime.rfc3339,
                                    time_max: @outer_end_time.to_datetime.rfc3339)

    response.items.select {|e| e.summary.to_s.start_with?(@event_name_prefix) }
  end

  def new_work_event(title, start_timestr, end_timestr, client_color_id)
    Google::Apis::CalendarV3::Event.new(
      summary: "#{@event_name_prefix} #{title}",
      description: 'You better work',
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_timestr, time_zone: @time_zone),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: end_timestr, time_zone: @time_zone),
      reminders: Google::Apis::CalendarV3::Event::Reminders.new(
        use_default: false,
        overrides: []
      ),
      color_id: client_color_id
    )
  end

  def initialize_planning_slots(total_hours)
    num_slots = WEEK_DAYS.size
    slot_hours_per_day = round_to_quarter(total_hours / num_slots.to_f, :ceil)
    Slotter.new(num_slots, slot_hours_per_day, time_datestr(@start_time), @offset_str)
  end

  private

  def days_in_month(t)
    Date.new(t.year, t.month, -1).day
  end

  def weeks_in_month(t)
    days_in_month(t) / 7.0
  end

end
