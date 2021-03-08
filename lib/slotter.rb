class Slot

  def initialize(size_hours, boundary_start, boundary_end, time_marker)
    @hours_remaining = size_hours
    @time_marker = time_marker

    @start_time = time_marker
    @end_time = time_marker + size_hours * HOUR

    @outer_start_time = boundary_start
    @outer_end_time = boundary_end
  end

  def find_best_fitting_item(items)
    item_fits = items.map {|c| [c, @hours_remaining - c] }
    best_fitting_item, _ = item_fits.sort_by {|c, f| f }.select {|c, f| f >= 0 }.first
    # puts "Best fitting item: #{best_fitting_item} #{items.inspect} #{@hours_remaining}"
    best_fitting_item
  end

  def insert(item_hours)
    @hours_remaining -= item_hours
    start_timestr = @time_marker.to_datetime.rfc3339
    @time_marker += item_hours * HOUR
    end_timestr = @time_marker.to_datetime.rfc3339
    [start_timestr, end_timestr]
  end

  def contains?(item_start_time, item_end_time)
    item_start_time >= @outer_start_time && item_end_time <= @outer_end_time
  end

end


class Slotter

  # NOTE -- there's no way to get working hours from the API unfortunately
  # TODO move to config
  MIN_SLOT_HOUR = 0
  MAX_SLOT_HOUR = 8

  MAX_SLOT_SIZE_HOURS = MAX_SLOT_HOUR - MIN_SLOT_HOUR

  def initialize(num_slots, slot_size_hours, start_time, offset_str)
    real_min_slot_hour = MAX_SLOT_HOUR - slot_size_hours
    # TODO -- is there a more precise way to determine this?
    # Add extra padding to each slot to account for weird packing issues
    real_min_slot_hour -= 0.25
    slot_size_hours += 0.25

    if slot_size_hours > MAX_SLOT_SIZE_HOURS
      raise "Cannot fit slot of size #{slot_size_hours} hours into maximum of #{MAX_SLOT_SIZE_HOURS} hours"
    end

    slot_boundary_start = parse_time_with_offset(start_time, offset_str, MIN_SLOT_HOUR)
    slot_boundary_end = parse_time_with_offset(start_time, offset_str, MAX_SLOT_HOUR)

    first_time_marker = parse_time_with_offset(start_time, offset_str, real_min_slot_hour)
    @slot_marker = 0
    @slots = num_slots.times.map do |i|
      Slot.new(slot_size_hours, slot_boundary_start + i * DAY, slot_boundary_end + i * DAY, first_time_marker + i * DAY)
    end
  end

  def current_slot
    @slots[@slot_marker]
  end

  def next_slot!
    if @slot_marker < @slots.size - 1
      @slot_marker += 1
    else
      raise "Should not move past max slots"
    end
  end

  def slot(item_hours)
    current_slot.insert(item_hours)
  end

  def any_slots_contain?(item_start_time, item_end_time)
    @slots.any? {|s| s.contains?(item_start_time, item_end_time) }
  end

end
