class TimeView < UIView
  attr_accessor :time_zone, :offset, :zoom

  NORMAL_SLOT_WIDTH = 40

  def init
    @offset = 0
    @zoom = 1.0
    @slot_width = NORMAL_SLOT_WIDTH
    start_timer
    super
  end

  def drawRect(rect)
    super

    context = UIGraphicsGetCurrentContext()
    CGContextSetFillColorWithColor(context, UIColor.whiteColor.CGColor)
    CGContextFillRect(context, rect)

    hours = offset / @slot_width

    time = current_time
    time = time.getlocal(@time_zone.secondsFromGMTForDate(NSDate.dateWithTimeIntervalSince1970(time.to_i)))
    time = time.beginning_of_hour
    time = time.advance(:hours => -(hours + num_slots / 2 + 1).to_i)
    time = time.getutc

    loc = self.location
    if loc
      (-1..2).to_a.each do |date_offset|
        CGContextSetFillColorWithColor(context, "#ffffec".to_color.CGColor)
        date = time.to_date + date_offset
        sunrise = cached_sunrise(date, loc)
        sunset = cached_sunset(date, loc)

        if sunrise.is_a?(Symbol) || sunset.is_a?(Symbol)
          if sunrise.to_s == 'up_all_day'
            day = date.to_time.getlocal(@time_zone.secondsFromGMT)
            x1 = x_coordinate_for(day.beginning_of_day)
            x2 = x_coordinate_for(day.end_of_day)

            CGContextFillRect(context, CGRectMake(x1, 25, x2-x1, self.frame.size.height))

            break if x1 > Device.screen.width_for_orientation
          end
        else
          x1 = x_coordinate_for(sunrise)
          x2 = x_coordinate_for(sunset)

          CGContextFillRect(context, CGRectMake(x1, 25, x2-x1, self.frame.size.height))

          break if x1 > Device.screen.width_for_orientation
        end
      end
    end

    CGContextSetStrokeColorWithColor(context, UIColor.blackColor.CGColor)

    CGContextSetFillColorWithColor(context, UIColor.blackColor.CGColor)

    x = x_coordinate_for(time)
    prev_hour = nil

    (-1..num_slots + 1).to_a.each do |i|
      local_time = time.getlocal(@time_zone.secondsFromGMTForDate(NSDate.dateWithTimeIntervalSince1970(time.to_i)))

      if prev_hour && prev_hour + 1 != local_time.hour
        CGContextSetLineWidth(context, 2.0)
      else
        CGContextSetLineWidth(context, 1.0)
      end

      draw_line(context, x, 25, x, 100)

      string = local_time.hour.to_s
      string.drawAtPoint(CGPointMake(x + 10, 30), withFont:UIFont.systemFontOfSize(14))

      prev_hour = local_time.hour

      if local_time.hour == 0
        string = local_time.day.to_s
        string.drawAtPoint(CGPointMake(x + 10, 75), withFont:UIFont.boldSystemFontOfSize(14))
      end

      if @slot_width > 60
        CGContextSetLineWidth(context, 1.0)

        half_slot = @slot_width / 2.0
        draw_line(context, x + half_slot, 35, x + half_slot, 100)

        if @slot_width > 100
          quarter_slot = @slot_width / 4.0
          draw_line(context, x + quarter_slot, 45, x + quarter_slot, 100)
          draw_line(context, x + half_slot + quarter_slot, 45, x + half_slot + quarter_slot, 100)
        end
      end

      time = time.advance(:hours => 1)
      x += @slot_width
    end

    marker = x_coordinate_for(current_time)
    if marker > 0 && marker < Device.screen.width_for_orientation
      CGContextSetLineWidth(context, 1.0)
      CGContextSetStrokeColorWithColor(context, UIColor.redColor.CGColor)

      draw_line(context, marker, 0, marker, 100)
    end
  end

  def time_zone=(value)
    @time_zone = value
    @sunrises = {}
    @sunsets = {}
  end

  def offset=(value)
    @offset = value
    self.setNeedsDisplay
  end

  def zoom=(value)
    @zoom = value
    @slot_width = NORMAL_SLOT_WIDTH * value
    self.setNeedsDisplay
  end

  def start_timer
    NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector:"tick:", userInfo:nil, repeats:true)
  end

  def tick(timer)
    if Time.now.sec == 0
      self.setNeedsDisplay
    end
  end

protected
  def current_time
    Time.now.getutc
  end

  def draw_line(context, x1, y1, x2, y2)
    CGContextMoveToPoint(context, x1, y1)
    CGContextAddLineToPoint(context, x2, y2)

    CGContextStrokePath(context)
  end

  def num_slots
    Device.screen.width_for_orientation / @slot_width
  end

  def half_screen_width
    Device.screen.width_for_orientation / 2.0
  end

  def x_coordinate_for(time)
    half_screen_width + (time - current_time) / 60 * pixel_per_minute + offset
  end

  def pixel_per_minute
    @slot_width.to_f / 60.0
  end

  def location
    coords = TIME_ZONE_LOCATIONS[time_zone.name.to_s]
    Sunrise::Location.new(coords.first.to_f, coords.last.to_f) if coords
  end

  def cached_sunrise(date, loc)
    @sunrises[date.to_s] ||= Sunrise.sunrise(date, loc)
  end

  def cached_sunset(date, loc)
    @sunsets[date.to_s] ||= Sunrise.sunset(date, loc)
  end
end
