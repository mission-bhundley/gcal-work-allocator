require 'bundler/setup'
require_relative 'google_auth'
require 'time'
require 'tzinfo'

CLIENT_HOURS_PATH = './client_hours.json'
APPLICATION_NAME = "Mission Google Calendar Work Allocator"
CALENDAR_ID = 'primary'
CAL_EVENT_PREFIX = '[WORK]'


client_hours = JSON.parse(File.read(CLIENT_HOURS_PATH))


# Initialize the API
service = Google::Apis::CalendarV3::CalendarService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize





time_zone = service.get_calendar(CALENDAR_ID).time_zone

offset = TZInfo::Timezone.get(time_zone).utc_offset
offset_prefix = offset >= 0 ? '+' : ''
offset_str = "#{offset_prefix}#{offset}"





time = nil
if ENV['DATE']
  time = Time.parse(ENV['DATE'])
else
  time = Time.now
end

datestr = time.strftime('%Y-%m-%d')



start_of_week = time - time.wday * 24*60*60
start_of_week = Time.parse("#{start_of_week.strftime('%Y-%m-%d')}T00:00:00#{offset_str}")
end_of_week = time + (6 - time.wday) * 24*60*59
end_of_week = Time.parse("#{end_of_week.strftime('%Y-%m-%d')}T23:59:59#{offset_str}")






response = service.list_events(CALENDAR_ID,
                               max_results: 100,
                               single_events: true,
                               time_min: start_of_week.to_datetime.rfc3339,
                               time_max: end_of_week.to_datetime.rfc3339)




remaining_client_hours = client_hours.dup

existing_events = response.items.select {|e| e.summary.to_s.start_with?(CAL_EVENT_PREFIX) }

existing_events.each do |event|
  client_name = event.summary.gsub("#{CAL_EVENT_PREFIX} ", '')

  if !client_hours[client_name]
    raise "Do not have hours configured for client with name '#{client_name}'"
  end

  hours_worked = (event.end.date_time.to_time - event.start.date_time.to_time) / 60.0 / 60.0

  remaining_client_hours[client_name] -= hours_worked
end





# puts "Upcoming events:"
# puts "No upcoming events found" if response.items.empty?
# response.items.each do |event|
#   start = event.start.date || event.start.date_time
#   puts "- #{event.summary} (#{start})"
# end






# ------------------------------------------------------------------------------------------ REMAINING CLIENT HOURS









def round_to_quarter(num)
  (num * 4).round / 4.0
end

def sum(arr)
  arr.inject(:+).to_f
end


CHUNK_SIZES = [1, 0.5, 0.25]

client_chunks = {}

remaining_client_hours.each do |client, hours|
  chunks = []
  while (remaining_hours = round_to_quarter(hours - sum(chunks))) > 0
    chunk_size = CHUNK_SIZES.select {|x| remaining_hours / x > 1 }.max || CHUNK_SIZES.min
    chunks << chunk_size
  end

  puts "#{client}: #{hours} #{sum(chunks)} - #{chunks.inspect}"

  client_chunks[client] = chunks
end





# require 'byebug'; byebug


colors = service.get_color.to_h[:calendar]
green_hexes = ['#16a765', '#42d692']
green_ids = colors.select {|_, v| green_hexes.include?(v[:background]) }.keys.map(&:to_s)


MAX_HOUR_CAP = 8

max_hours = [
  client_chunks.map {|_, v| sum(v) }.max,
  MAX_HOUR_CAP
].min








# NOTE -- there's no way to get working hours from the API unfortunately
starting_work_hour = 8

starting_hour = starting_work_hour - max_hours





# overrides: [
#   Google::Apis::CalendarV3::EventReminder.new(
#     reminder_method: 'email',
#     minutes: 24 * 60
#   ),
#   Google::Apis::CalendarV3::EventReminder.new(
#     reminder_method: 'popup',
#     minutes: 10
#   )
# ]
# recurrence: [
#   'RRULE:FREQ=DAILY;COUNT=2'
# ],
# attendees: [
#   Google::Apis::CalendarV3::EventAttendee.new(
#     email: 'lpage@example.com'
#   ),
#   Google::Apis::CalendarV3::EventAttendee.new(
#     email: 'sbrin@example.com'
#   )
# ],



client_chunks.each do |client, chunks|

  hour_marker = starting_hour
  min_marker = 0

  chunks.each do |hours|


    start_timestr = "#{datestr}T#{'%02d' % hour_marker}:#{'%02d' % min_marker}:00#{offset_str}"

    mins = (hours * 60).round

    end_time = Time.parse(start_timestr) + mins*60


    require 'byebug'; byebug



    hour_marker += hours
    min_marker
  end
end






start_time = Google::Apis::CalendarV3::EventDateTime.new(date_time: start_timestr, time_zone: time_zone)
end_time = Google::Apis::CalendarV3::EventDateTime.new(date_time: end_timestr, time_zone: time_zone)

event = Google::Apis::CalendarV3::Event.new(
  summary: "#{CAL_EVENT_PREFIX} #{client}",
  description: 'You better work',
  start: start_time,
  end: end_time,
  reminders: Google::Apis::CalendarV3::Event::Reminders.new(
    use_default: false,
    overrides: []
  )
)

result = client.insert_event(CALENDAR_ID, event)
