class BundlesController < ApplicationController
  include BilgePump::Controller

  model_scope [:project]
  model_class Bundle

  def move_feature
    direction = params[:direction]
    @bundle = find_model(model_scope, params[:id])
    feature = Feature.find(params[:feature_id])

    case true
    when feature.needs_discussion?
      order = @bundle.needing_discussion_order
    when feature.ready_for_estimate?
      order = @bundle.ready_for_estimate_order
    when feature.ready_to_schedule?
      order = @bundle.ready_to_schedule_order
    end
    new_order(feature, order, direction)
    @bundle.save
    redirect_to project_bundle_path
  end


  def create_bundle_feature
    new_feature_params_hash = get_bundled_feature_params_and_id_check_hash
    return redirect_to project_path(@project) if new_feature_params_hash.empty?
    @feature = Feature.new(new_feature_params_hash)
    @feature.story_type = TrackerIntegration::StoryType::Feature
    @bundle = find_model(model_scope, params[:id])
    if @feature.save 
      @bundle.needing_discussion_order.push(@feature.id)
      @bundle.save
      flash[:notice] = "Feature was created"
    else
      flash[:alert] = @feature.errors.full_messages
      populate_bundled_features(@bundle)
      return render 'show'
    end
    redirect_to project_bundle_path
  end

  def show
    @feature = Feature.new
    @bundle = find_model(model_scope, params[:id])
    populate_bundled_features(@bundle)
    respond_with @bundle
  end

  def add_feature
    feature = Feature.find(params[:feature_id])
    bundle = Bundle.find(params[:id])
    feature.bundles.push(bundle)
    feature.save!
    redirect_to project_bundle_path
  end

  def remove_feature
    feature = Feature.find(params[:feature_id])
    bundle = Bundle.find(params[:id])
    feature.bundle_ids.delete(bundle.id)
    feature.save!
    redirect_to project_bundle_path
  end

  def schedule
    @bundle = find_model(model_scope, params[:id])
    features_to_schedule = features_preserve_order_for_tracker(@bundle)

    fail_messages = []
    fail_messages << "Please add features to the bundle before scheduling." unless features_to_schedule.any?

    features_to_schedule.each do |f|
      begin
        f.create_in_tracker
        if !f.save
          fail_messages << f.errors.full_messages
        elsif f.tracker_errors.any?
          fail_messages = fail_messages + f.tracker_errors
        end
      rescue
        fail_messages << "Caught exception from Tracker on feature #{f.name}"
      end
    end

    if fail_messages.any?
      flash[:error] = fail_messages.join(',')
    else
      flash[:notice] = 'All features have successfully been loaded onto Pivotal Tracker'
    end

    redirect_to project_bundle_path
  end

  protected

  def new_order(feature,order,direction)
    feature_index = order.index(feature.id)
    # raise "wtf"
    if direction == 'up'
      new_position_index = feature_index!=0 ? (feature_index-1) : nil
      if new_position_index != nil
        order.slice!(feature_index)
        order.insert(new_position_index,feature.id)
      else
        nil
      end
    elsif direction == 'down'
      new_position_index = feature_index!= (order.count-1) ? (feature_index+1) : nil
        if new_position_index != nil
          order.slice!(feature_index)
          order.insert(new_position_index,feature.id)
        else
          nil
        end
    end
  end

  def get_bundled_feature_params_and_id_check_hash
    feature_params = params[:feature]

    begin
      bundle = @project.bundles.find(params[:id])
      if bundle != nil
        labels = Bundle.labels_formate(feature_params[:labels])
        new_hash = { project_id: @project.id,
                     bundle_ids: [bundle.id],
                     labels: labels
                   }
        return feature_params.merge(new_hash)
      end

      raise 'You cannot save feature in another bundle'
    rescue Exception => e
      flash[:alert] = e.message
      {}
    end
  end

  def populate_bundled_features(bundle)
    @available_features = bundle.available_features
    @bundled_features = bundle.features_ready_to_schedule(@bundle.ready_to_schedule_order)
    @estimable_features = bundle.features_ready_for_estimate(@bundle.ready_for_estimate_order)
    @features_needing_discussion = bundle.features_needing_discussion(@bundle.needing_discussion_order)
  end

  def features_preserve_order_for_tracker(bundle)
    Feature.find_all_by_bundle_ids(bundle.id).reverse
  end
end
