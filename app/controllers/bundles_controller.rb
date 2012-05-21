class BundlesController < ApplicationController
  include BilgePump::Controller

  model_scope [:project]
  model_class Bundle

  def create_bundle_feature
    new_feature_params = get_bundled_feature_params_and_id_check(params)
      @feature = Feature.new(new_feature_params)
      if @feature.save
        flash[:notice] = "Feature was created"
      else
        flash[:alert] = @feature.errors.full_messages
      end
    redirect_to project_bundle_path
  end

  def show
    @bundle = find_model(model_scope, params[:id])
    @available_features = @bundle.available_features
    @bundled_features = @bundle.features_ready_to_schedule
    @estimable_features = @bundle.features_ready_for_estimate
    @features_needing_discussion = @bundle.features_needing_discussion
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
    features_to_schedule = Feature.find_all_by_bundle_ids(@bundle.id)

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
end
