class TimePlaneCell < UITableViewCell
  attr_accessor :time_zone

  def init
    super

    self.stylesheet = :time_plane_cell
    self.selectionStyle = UITableViewCellSelectionStyleNone

    layout self, :cell do
      @time_view = subview(TimeView, :timeline)
      @name_label = subview(UILabel, :name)
      @time_label = subview(UILabel, :time)
    end

    self
  end

  def time_zone=(value)
    @time_zone = value
    @name_label.text = value.name.gsub('_', ' ')
    @time_view.time_zone = @time_zone

    update_time_label
    start_timer
    resize_time_view
  end

  delegate :offset=, :zoom=, :to => '@time_view'

  def setEditing(editing, animated:animated)
    super

    if (animated)
      UIView.animateWithDuration(0.2, delay:0.0, options:UIViewAnimationOptionCurveEaseInOut, animations:lambda {
        resize_time_view
      }, completion:nil)
    else
      resize_time_view
    end
  end

  def tick(timer)
    if Time.now.sec == 0
      update_time_label
    end
  end

private
  def start_timer
    NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector:"tick:", userInfo:nil, repeats:true)
  end

  def update_time_label
    time = Time.now.getlocal(@time_zone.secondsFromGMT)
    @time_label.text = time.strftime "%k:%M"
  end

  def resize_time_view
    frame = @time_view.frame
    width = Device.screen.width_for_orientation

    if isEditing
      @time_view.setFrame([[40, frame.origin.y], [width - 80, frame.size.height]])
    else
      @time_view.setFrame([[0, frame.origin.y], [width, frame.size.height]])
    end

    @time_view.setNeedsDisplay
  end
end
