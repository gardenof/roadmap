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


  def new_order(feature,order,direction)
    feature_index = order.index(feature.id)
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

  def create_bundle_feature
    new_feature_params = get_bundled_feature_params_and_id_check(params)
      @feature = Feature.new(new_feature_params)
      if @feature.save
        @bundle = find_model(model_scope, params[:id])
        @bundle.needing_discussion_order.push(@feature.id)
        @bundle.save
        flash[:notice] = "Feature was created"
      else
        flash[:alert] = @feature.errors.full_messages
      end
    redirect_to project_bundle_path
  end

  def show
    @bundle = find_model(model_scope, params[:id])
    @available_features = @bundle.available_features
    @bundled_features = @bundle.features_ready_to_schedule(@bundle.ready_to_schedule_order)
    @estimable_features = @bundle.features_ready_for_estimate(@bundle.ready_for_estimate_order)
    @features_needing_discussion = @bundle.features_needing_discussion(@bundle.needing_discussion_order)
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

  def get_bundled_feature_params_and_id_check(params)
    feature_params = params[:feature]

    begin
      bundle = @project.bundles.find(params[:id])
      if bundle != nil
        labels = Bundle.labels_formate(feature_params[:labels])
        new_hash = { project_id: @project.id,
                     bundle_ids: [bundle.id],
                     labels: labels
                   }
        feature_params.merge(new_hash)
      end
    rescue Exception => e
      e
    end
  end

  def features_preserve_order_for_tracker(bundle)
    Feature.find_all_by_bundle_ids(bundle.id).reverse
  end
end
