module FeatureHelper
  def format_float(number)
    number_with_precision(number, precision:1)
  end

  def tracker_status_class(feature)
    feature.current_state
  end
  def find_total_estimate(feature)
    if feature.estimate == nil
      ""
    else
      "#{feature.estimate}"
    end
  end

  def iteration_format(iteration)
     iteration.day.to_s + " " + Date::MONTHNAMES[iteration.month - 1]
  end
end