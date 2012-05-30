class FeaturesController < ApplicationController
  include BilgePump::Controller

  model_scope [:project]
  model_class Feature

  PER_PAGE = 10


  def index
    @features = @project.features.paginate(page: params[:page], per_page: PER_PAGE)
  end

  def edit
    @feature = Feature.find(params[:id])
    if @feature.updatable?
      edit_project_feature_path(@project, @feature)
    else
      flash[:notice] = "Can't update feature attributes after Tracker refresh"
      redirect_to project_feature_path(@project, @feature)
    end
  end

  def update
    @feature = Feature.find(params[:id])
    associated_bundle_id = params[:redirect_to_bundle_id]
    if @feature.updatable?
      @feature.update_attributes(params[:feature])
      update_bundle_order_arrays(@feature, @feature.bundles)
      if associated_bundle_id != nil
       return redirect_to project_bundle_path(@project, associated_bundle_id)
      end
    else
      flash[:notice] = "Can't update feature attributes after Tracker refresh"
      if associated_bundle_id != nil
       return redirect_to project_bundle_path(@project, associated_bundle_id)
      end
    end
    redirect_to project_feature_path(@project, @feature)
  end

  def destroy
    @feature = Feature.find(params[:id])
    associated_bundle_id = params[:redirect_to_bundle_id]
    if @feature.updatable?
      remove_bundle_id_from_order_array(@feature, @feature.bundles)
      @feature.destroy
      if associated_bundle_id != nil
        return redirect_to project_bundle_path(@project, associated_bundle_id)
      end
    else
      flash[:notice] = "Can't delete feature attributes after Tracker refresh"
      if associated_bundle_id != nil
        return redirect_to project_bundle_path(@project, associated_bundle_id)
      end
    end
    redirect_to project_path(@project)
  end

  def tagged
    @features = @project.features.with_label(params[:value]).paginate(page: params[:page], per_page: PER_PAGE)
    render 'index' , project_id: @project.id
  end

  def schedule
    @feature = Feature.find(params[:feature_id])

    # create the story in tracker
    @feature.create_in_tracker
    @feature.save

    redirect_to project_feature_path(@project, @feature)
  end

  def tracker_web_hook
    story_hash = params["activity"]["stories"][0]
    if story_hash["labels"] != nil
      labels = story_hash["labels"].split(',')
    end
    story_updates = story_hash.deep_merge({:story_id =>story_hash["id"],:labels => labels})
                              .slice(:story_id,
                                     :name,
                                     :description,
                                     :estimate,
                                     :labels,
                                     :story_type,
                                     :current_state)
    if params["activity"]['event_type'] == "story_update"
      feature = Feature.find_by_story_id(story_hash['id'].to_i)
      feature.update_attributes(story_updates)
      render text: "ok"
    end
  end

  protected

  def update_bundle_order_arrays(feature, bundles)
    bundle = bundles.first
    return if bundle == nil
    if feature.ready_for_estimate? && bundle.needing_discussion_order.include?(feature.id)
      bundle.needing_discussion_order.delete feature.id
      bundle.ready_for_estimate_order.push feature.id
    elsif feature.ready_to_schedule? && bundle.ready_for_estimate_order.include?(feature.id)
      bundle.ready_for_estimate_order.delete feature.id
      bundle.ready_to_schedule_order.push feature.id
    end
    bundle.save
  end

  def remove_bundle_id_from_order_array(feature, bundles)
    bundle = bundles.first
    return if bundle == nil
    case true
    when bundle.needing_discussion_order.include?(feature.id)
      bundle.needing_discussion_order.delete feature.id
    when bundle.ready_for_estimate_order.include?(feature.id)
      bundle.ready_for_estimate_order.delete feature.id
    when bundle.ready_to_schedule_order.include?(feature.id)
      bundle.ready_to_schedule_order.delete feature.id
    end
    bundle.save
  end
end


