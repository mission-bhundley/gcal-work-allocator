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
