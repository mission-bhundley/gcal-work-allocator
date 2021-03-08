HOUR = 60 * 60
DAY = 24 * HOUR

def time_datestr(t)
  t.strftime('%Y-%m-%d')
end

def round_to_quarter(num, meth=:round)
  (num * 4).send(meth) / 4.0
end

def sum(arr)
  arr.inject(:+).to_f
end

def truncate(str, len)
  if str.size > len
    return str[0, len - 3] + '...'
  end
  str
end

def printable_calendar_event(e)
  start_time = Time.parse(e.start.date_time.to_s)
  end_time = Time.parse(e.end.date_time.to_s)

  truncate(e.summary, 30).ljust(31) +
  "\t" +
  start_time.strftime('%a, %b %e').ljust(15) +
  start_time.strftime('%l:%M%p') +
  "  - " +
  end_time.strftime('%l:%M%p')
end

def parse_datestr_with_offset(datestr, offset_str, hour=0, min=0, sec=0)
  Time.parse("#{datestr}T#{'%02d' % hour}:#{'%02d' % min}:#{'%02d' % sec}#{offset_str}")
end

def parse_time_with_offset(time, offset_str, hour=0, min=0, sec=0)
  parse_datestr_with_offset(time_datestr(time), offset_str, hour, min, sec)
end

def now_with_offset(offset_str)
  parse_time_with_offset(Time.now, offset_str)
end
