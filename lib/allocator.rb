require_relative 'helpers'
require 'ansi'

class Allocator

  CHUNK_SIZES = [1, 0.5, 0.25]

  def initialize(work_week, config, service)
    @work_week = work_week

    @service = service

    @color_hexes = config['color_hexes']
    colors = @service.get_color.event
    @color_ids = colors.select {|_, v| @color_hexes.include?(v.background) }.keys.map(&:to_s)

    @calendar_id = config['calendar_id']
    @event_name_prefix = config['event_name_prefix']

    @projects = config['projects']

    generate_chunks
    initialize_slotter
  end

  def allocate_work
    events = []
    @unslotted_client_chunks.each_with_index do |x, i|
      client, chunks = x

      client_color_id = @color_ids[i % @color_ids.size]

      while chunks.any?
        best_fitting_chunk = @slotter.current_slot.find_best_fitting_item(chunks)

        # Go to next slot (day) if there's no fit
        if !best_fitting_chunk
          @slotter.next_slot!
          next
        end

        # Remove chunk
        chunks.delete_at(chunks.index(best_fitting_chunk))

        # Slot
        start_timestr, end_timestr = @slotter.slot(best_fitting_chunk)

        # Add to events
        events << @work_week.new_work_event(client, start_timestr, end_timestr, client_color_id)
      end
    end


    # Insert events
    events.each do |e|
      puts ANSI.green { 'ADD' } + "\t#{printable_calendar_event(e)}"
      @service.insert_event(@calendar_id, e)
    end
  end



  def slotted_work
    @work_week.allocated_work.select do |e|
      @slotter.any_slots_contain?(e.start.date_time.to_time, e.end.date_time.to_time)
    end
  end

  def clear_slotted_work
    slotted_work.each do |e|
      puts ANSI.red { 'DEL' } + "\t#{printable_calendar_event(e)}"
      @service.delete_event(@calendar_id, e.id)
    end
  end




  private

  def initialize_slotter
    required_hours = sum(@unslotted_client_chunks.values.flatten)
    @slotter = @work_week.initialize_planning_slots(required_hours)
  end

  def generate_chunks
    # Calculate weekly project hours
    project_weekly_hours = {}
    @projects.each do |project|
      monthly_hour_share = (project['hours_per_month'] * project['work_share']).to_f
      weekly_hour_share = monthly_hour_share / @work_week.weeks_this_month
      weekly_hour_share -= project['pre_booked_hours_per_week']
      project_weekly_hours[project['name']] = weekly_hour_share
    end

    # Calculate _remaining_ weekly project hours
    existing_events = @work_week.allocated_work
    remaining_project_weekly_hours = project_weekly_hours.dup
    existing_events.each do |event|
      client_name = event.summary.gsub("#{@event_name_prefix} ", '')
      if !project_weekly_hours[client_name]
        raise "Do not have hours configured for client with name '#{client_name}'"
      end
      hours_worked = (event.end.date_time.to_time - event.start.date_time.to_time).to_f / HOUR
      remaining_project_weekly_hours[client_name] -= hours_worked
    end

    # Create "chunks" of hours for each client (trying to give a decent variety)
    # @all_client_chunks = create_project_chunks(project_weekly_hours)
    @unslotted_client_chunks = create_project_chunks(remaining_project_weekly_hours)
  end

  def create_project_chunks(project_hours)
    project_chunks = {}
    project_hours.each do |project, hours|
      chunks = []
      while (remaining_hours = round_to_quarter(hours - sum(chunks))) > 0
        chunk_size = CHUNK_SIZES.select {|x| remaining_hours / x > 1 }.max || CHUNK_SIZES.min
        chunks << chunk_size
      end
      # puts "#{project}: #{hours} #{sum(chunks)} - #{chunks.inspect}"
      project_chunks[project] = chunks
    end
    project_chunks
  end

end
