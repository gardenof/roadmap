class BundlesController < ApplicationController
  include BilgePump::Controller

  model_scope [:project]
  model_class Bundle

  def show
    @bundle = find_model(model_scope, params[:id])
    @available_features = @bundle.available_features
    @attached_features = @bundle.features
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

end
