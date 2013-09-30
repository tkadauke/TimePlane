class UIView
  def each_subview(&block)
    subviews.each do |subview|
      block.call(subview)
      subview.each_subview(&block)
    end
  end
end
