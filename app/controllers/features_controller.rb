class FeaturesController < ApplicationController
  include BilgePump::Controller

  model_scope [:project]
  model_class Feature

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
    if @feature.updatable?
      @feature.update_attributes(params[:feature])
      redirect_to project_feature_path(@project, @feature)
    else
      flash[:notice] = "Can't update feature attributes after Tracker refresh"
      redirect_to project_feature_path(@project, @feature)
    end
  end


  def tagged
    @features = Feature.with_label(params[:value]).all
    render 'index' , project_id: @project.id
  end

  def schedule
    @feature = Feature.find(params[:feature_id])

    # create the story in tracker
    story = TrackerIntegration.create_feature_in_tracker(
      params[:tracker_project_id],
      @feature
    )
    
    # set tracker id and save
    @feature.update(story)
    @feature.save

    redirect_to project_feature_path(@project, @feature)
  end

end
