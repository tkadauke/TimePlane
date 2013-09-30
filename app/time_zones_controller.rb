class TimeZonesController < UITableViewController
  attr_accessor :search_bar

  def initWithParent(parent)
    @filtered_time_zones = @time_zones = NSTimeZone.knownTimeZoneNames
    @parent = parent
    self
  end

  def viewDidLoad
    super

    self.title = "Add Time Zone"

    @cancel_button = UIBarButtonItem.alloc.initWithTitle("Cancel", style:UIBarButtonItemStyleBordered, target:self, action:'cancel')

    self.navigationItem.rightBarButtonItem = @cancel_button

    tableView.tableHeaderView = build_search_bar
    self.searchDisplayController = build_search_controller
  end

  def tableView(tableView, numberOfRowsInSection:section)
    @filtered_time_zones.size
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    fresh_cell.tap do |cell|
      cell.text = @filtered_time_zones[indexPath.row].gsub('_', ' ')
    end
  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    time_zone = @filtered_time_zones[indexPath.row]
    @parent.add_time_zone(time_zone)
    self.dismissModalViewControllerAnimated(true)
  end

  def cancel
    self.dismissModalViewControllerAnimated(true)
  end

  def searchDisplayController(controller, shouldReloadTableForSearchString:string)
    self.filter_search(string, animated:false)
    true
  end

  def filter_search(string, animated:animated)
    string ||= @search_bar.text || ""
    string = string.downcase

    if string.blank?
      @filtered_time_zones = @time_zones
    else
      @filtered_time_zones = @time_zones.select { |tz| tz.gsub('_', ' ').downcase.include?(string) }
    end

    if animated
      table_view_for_context.reloadSections(NSIndexSet.indexSetWithIndex(0), withRowAnimation:UITableViewRowAnimationFade)
    else
      table_view_for_context.reloadData
    end
  end

  def searchBarCancelButtonClicked(searchBar)
    filter_search("", animated:true)
  end

protected
  def fresh_cell
    table_view_for_context.dequeueReusableCellWithIdentifier('Cell') ||
    UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier:'Cell')
  end

  def table_view_for_context
    if self.searchDisplayController.isActive
      searchDisplayController.searchResultsTableView
    else
      self.tableView
    end
  end

  def build_search_bar
    @search_bar = UISearchBar.alloc.initWithFrame([[0, 0], [320, 44]])
    @search_bar.delegate = self
    @search_bar
  end

  def build_search_controller
    UISearchDisplayController.alloc.initWithSearchBar(@search_bar, contentsController:self).tap do |controller|
      controller.delegate = self
      controller.searchContentsController = self
      controller.searchResultsDataSource = self
      controller.searchResultsDelegate = self
      controller.searchResultsTableView.backgroundColor = UIColor.whiteColor
    end
  end
end
