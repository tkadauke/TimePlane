class TimePlaneController < UITableViewController
  def init
    @defaults = NSUserDefaults.standardUserDefaults

    @time_zones = (@defaults.objectForKey('time_zones') || []).map { |tz| NSTimeZone.timeZoneWithName(tz) }
    @time_zones = [NSTimeZone.localTimeZone] if @time_zones.empty?
    @zoom = @prev_zoom = 1.0
    self.title = 'TimePlane'
    now
    super
  end

  def viewDidLoad
    super

    @pan = UIPanGestureRecognizer.alloc.initWithTarget(self, action:'panHandler:')
    @pan.delegate = self
    self.tableView.addGestureRecognizer(@pan)

    @pinch = UIPinchGestureRecognizer.alloc.initWithTarget(self, action:'pinchHandler:')
    @pinch.setDelegate(self)
    self.tableView.addGestureRecognizer(@pinch)

    @plus_button = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemAdd, target:self, action:'add')
    @edit_button = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemEdit, target:self, action:'edit')
    @done_button = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemDone, target:self, action:'done_editing')

    @now_button = UIBarButtonItem.alloc.initWithTitle("Now", style:UIBarButtonItemStyleBordered, target:self, action:'now')

    self.navigationItem.setRightBarButtonItems [@plus_button, @edit_button]
    self.navigationItem.leftBarButtonItem = @now_button
  end

  def gestureRecognizerShouldBegin(gestureRecognizer)
    case gestureRecognizer
    when @pan
      translate = gestureRecognizer.translationInView(self.tableView)

      if translate.x.abs > translate.y.abs
        true
      else
        false
      end
    else
      true
    end
  end

  def panHandler(sender)
    if sender.state == UIGestureRecognizerStateChanged
      translate = sender.translationInView(self.view)
      @offset = @prev_offset + translate.x
      scroll_cells
    elsif sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled
      @prev_offset = @offset
    end
  end

  def pinchHandler(sender)
    if sender.state == UIGestureRecognizerStateChanged
      @zoom = @prev_zoom * sender.scale
      zoom_cells
    elsif sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled
      @prev_zoom = clip_zoom(@zoom)
    end
  end

  def tableView(tableView, numberOfRowsInSection:section)
    @time_zones.size
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    fresh_cell.tap do |cell|
      cell.time_zone = @time_zones[indexPath.row]
      cell.offset = @offset
    end
  end

  def tableView(tableView, heightForRowAtIndexPath: indexPath)
    100
  end

  def tableView(tableView, canMoveRowAtIndexPath:indexPath)
    true
  end

  def tableView(tableView, moveRowAtIndexPath:source, toIndexPath:dest)
    time_zone = @time_zones.delete_at(source.row)
    @time_zones.insert(dest.row, time_zone)

    save
  end

  def tableView(tableView, editingStyleForRowAtIndexPath:indexPath)
    if @editing
      UITableViewCellEditingStyleDelete
    else
      UITableViewCellEditingStyleNone
    end
  end

  def tableView(tableView, commitEditingStyle:editingStyle, forRowAtIndexPath:indexPath)
    if editingStyle == UITableViewCellEditingStyleDelete
      @time_zones.delete(@time_zones[indexPath.row])
      tableView.reloadData

      save
    end
  end

  def add
    self.presentModalViewController(UINavigationController.alloc.initWithRootViewController(TimeZonesController.alloc.initWithParent(self)), animated: true)
  end

  def add_time_zone(time_zone)
    @time_zones << NSTimeZone.timeZoneWithName(time_zone)
    tableView.reloadData

    save
  end

  def edit
    @editing = true
    tableView.setEditing true, animated:true
    @pan.enabled = false
    self.navigationItem.setRightBarButtonItems [@plus_button, @done_button]
  end

  def done_editing
    @editing = false
    tableView.setEditing false, animated:true
    @pan.enabled = true
    self.navigationItem.setRightBarButtonItems [@plus_button, @edit_button]
  end

  def now
    @offset = @prev_offset = Device.screen.width / 2.0
    scroll_cells
  end

protected
  def fresh_cell
    tableView.dequeueReusableCellWithIdentifier('Cell') || TimePlaneCell.alloc.init.tap do |cell|
      cell.reuseIdentifier = 'Cell'
    end
  end

  def scroll_cells
    each_cell do |cell|
      cell.offset = @offset
    end
  end

  def zoom_cells
    clipped = clip_zoom(@zoom)
    each_cell do |cell|
      cell.zoom = clipped
    end
  end

  def each_cell(&block)
    tableView.each_subview do |view|
      if view.is_a?(TimePlaneCell)
        block.call(view)
      end
    end
  end

  def save
    @defaults.setObject(@time_zones.map(&:name), forKey:"time_zones")
  end

  def clip_zoom(zoom)
    if zoom < 0.75
      0.75
    elsif zoom > 5
      5
    else
      zoom
    end
  end
end
