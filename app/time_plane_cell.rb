class TimePlaneCell < UITableViewCell
  attr_accessor :time_zone

  def init
    super

    self.stylesheet = :time_plane_cell
    self.selectionStyle = UITableViewCellSelectionStyleNone

    layout self, :cell do
      @name_label = subview(UILabel, :name)
      @time_view = subview(TimeView, :time)
    end
    self
  end

  def time_zone=(value)
    @time_zone = value
    @name_label.text = value.name.gsub('_', ' ')
    @time_view.time_zone = @time_zone
  end

  def offset=(value)
    @time_view.offset = value
  end

  def setEditing(editing, animated:animated)
    super

    if (animated)
      UIView.animateWithDuration(0.2, delay:0.0, options:UIViewAnimationOptionCurveEaseInOut, animations:lambda {
        frame = @time_view.frame;

        if (editing)
          @time_view.setFrame([[40, frame.origin.y], [240, frame.size.height]])
        else
          @time_view.setFrame([[0, frame.origin.y], [320, frame.size.height]])
        end

        @time_view.setNeedsDisplay
      }, completion:nil)
    end
  end
end
