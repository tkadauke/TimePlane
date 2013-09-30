Teacup::Stylesheet.new :time_plane_cell do
  style :cell

  style :name,
    font: UIFont.boldSystemFontOfSize(17.0),
    textColor: UIColor.blackColor,
    highlightedTextColor: UIColor.whiteColor,
    autoresizingMask: UIViewAutoresizingFlexibleWidth,
    left: 50,
    top: 3,
    width: lambda { superview.bounds.size.width - 66 },
    height: 20
  
  style :time,
    left: 0,
    top: 25,
    width: lambda { superview.bounds.size.width },
    height: 75
end
