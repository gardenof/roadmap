Factory.define :tracker_iteration, class: PivotalTracker::Iteration do |f|
  f.sequence(:id)
  f.start Time.local(2012, 5, 30, 10,49, 1)
end