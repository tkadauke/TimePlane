class TimeView < UIView
  attr_accessor :time_zone, :offset

  SLOT_WIDTH = 40
  NUM_SLOTS = (320 / SLOT_WIDTH)

  def init
    @offset = 0
    start_timer
    super
  end

  def drawRect(rect)
    super

    context = UIGraphicsGetCurrentContext()
    CGContextSetFillColorWithColor(context, UIColor.whiteColor.CGColor)
    CGContextFillRect(context, rect)

    CGContextSetStrokeColorWithColor(context, UIColor.blackColor.CGColor)

    CGContextSetFillColorWithColor(context, UIColor.blackColor.CGColor)

    hours, shift = offset.divmod(SLOT_WIDTH)

    time = current_time
    time = time.advance(:hours => -(hours + 1))

    (-1..NUM_SLOTS + 1).to_a.each do |i|
      if time.hour == 0
        CGContextSetLineWidth(context, 2.0)
      else
        CGContextSetLineWidth(context, 1.0)
      end
      
      CGContextMoveToPoint(context, i * SLOT_WIDTH + shift, 0)
      CGContextAddLineToPoint(context, i * SLOT_WIDTH + shift, 80)

      CGContextStrokePath(context)

      string = time.hour.to_s
      string.drawAtPoint(CGPointMake(i * SLOT_WIDTH + 10 + shift, 5), withFont:UIFont.systemFontOfSize(14))

      if time.hour == 0
        string = time.day.to_s
        string.drawAtPoint(CGPointMake(i * SLOT_WIDTH + 10 + shift, 50), withFont:UIFont.boldSystemFontOfSize(14))
      end

      time = time.advance(:hours => 1)
    end

    marker = offset + current_time.min.to_f / 60.0 * SLOT_WIDTH
    if marker > 0 && marker < 320
      CGContextSetLineWidth(context, 1.0)
      CGContextSetStrokeColorWithColor(context, UIColor.redColor.CGColor)
      CGContextMoveToPoint(context, marker, 0)
      CGContextAddLineToPoint(context, marker, 80)
      CGContextStrokePath(context)
    end
  end

  def offset=(value)
    @offset = value
    self.setNeedsDisplay
  end

  def current_time
    Time.now.getlocal(@time_zone.secondsFromGMT)
  end

  def start_timer
    NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector:"tick:", userInfo:nil, repeats:true)
  end

  def tick(timer)
    if Time.now.sec == 0
      self.setNeedsDisplay
    end
  end
end
