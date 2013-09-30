Teacup::Stylesheet.new :time_plane_cell do
  style :cell

  style :name,
    font: UIFont.boldSystemFontOfSize(17.0),
    textColor: UIColor.blackColor,
    autoresizingMask: UIViewAutoresizingFlexibleWidth,
    left: 10,
    top: 3,
    width: lambda { superview.bounds.size.width - 66 },
    height: 20

  style :time,
    font: UIFont.systemFontOfSize(17.0),
    textColor: UIColor.blackColor,
    autoresizingMask: UIViewAutoresizingFlexibleWidth,
    textAlignment: UITextAlignmentRight,
    left: lambda { superview.bounds.size.width - 60 },
    top: 3,
    width: 50,
    height: 20

  style :timeline,
    autoresizingMask: UIViewAutoresizingFlexibleWidth,
    left: 0,
    top: 25,
    width: lambda { superview.bounds.size.width },
    height: 75
end
