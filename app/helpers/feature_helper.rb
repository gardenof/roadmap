module FeatureHelper
  def format_float(number)
    number_with_precision(number, precision:1)
  end

  def tracker_status_class(feature)
    feature.current_state
  end

end