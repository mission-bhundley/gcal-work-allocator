require 'bundler/setup'
require 'time'
require 'tzinfo'

require_relative 'lib/google_calendar_client'
require_relative 'lib/work_week'
require_relative 'lib/allocator'

CONFIG_PATH = File.expand_path('../config/config.yaml', __FILE__)

require 'thor'

class CLI < Thor
  desc "allocate", "Allocate work events."
  option :config, banner: "<config-file>", type: "string", aliases: ["c"], default: CONFIG_PATH
  option :date, banner: "<date>", type: "string", aliases: ["d"]
  long_desc <<-EOF
    Allocates "working time" events for projects to a Google calendar for a single week.

    Project and calendar settings are specified by --config <config-file>.

    With --date <date> option, you can control which week is targeted. Defaults to the current week.
  EOF
  def allocate
    allocator(options[:config], options[:date]).tap do |a|
      if a.slotted_work.any?
        raise "Already have slotted work. Use the `scrub` command to wipe first."
      end
      a.allocate_work
    end
  end

  desc "scrub", "Delete unused work events."
  option :config, banner: "<config-file>", type: "string", aliases: ["c"], default: CONFIG_PATH
  option :date, banner: "<date>", type: "string", aliases: ["d"]
  long_desc <<-EOF
    Deletes "working time" events from a Google calendar for a single week.

    Does NOT delete any events that are outside of the time slots the `allocate` command uses.
    This allows you to move events (in the Google Calendar UI) into actual working times, and
    then use those events for recording project hours later. By only scrubbing still-slotted
    times, we preserve the history of hour consumption per project.

    Project and calendar settings are specified by --config <config-file>.

    With --date <date> option, you can control which week is targeted. Defaults to the current week.
  EOF
  def scrub
    allocator(options[:config], options[:date]).clear_slotted_work
  end

  private

  def allocator(config_path, date)
    return @allocator if @allocator
    config = YAML.load_file(config_path)
    service = new_google_calendar_client
    work_week = WorkWeek.new(config, service, date)
    @allocator = Allocator.new(work_week, config, service)
  end

end



ENV['THOR_SILENCE_DEPRECATION'] = 'true'

CLI.start(ARGV)


# case ARGV[0]
#
# when 'allocate'
#   if allocator.slotted_work.any?
#     raise "Already have slotted work. Use the `scrub` command to wipe first."
#   end
#   allocator.allocate_work
#
# when 'scrub'
#   allocator.clear_slotted_work
#
# else
#   raise "Only know how to allocate, scrub"
# end
