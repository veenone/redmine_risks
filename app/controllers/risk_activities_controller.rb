class RiskActivitiesController < ApplicationController
  before_action :find_risk
  before_action :find_activity, only: [:show, :edit, :update, :destroy]
  before_action :authorize_manage_activities, except: [:index, :show]

  helper :risks
  include RisksHelper

  def index
    @activities = @risk.activities.by_planned_date
  end

  def show
  end

  def new
    @activity = @risk.activities.build
    @activity.author = User.current
  end

  def create
    @activity = @risk.activities.build
    @activity.author = User.current
    @activity.safe_attributes = params[:risk_activity]

    if @activity.save
      flash[:notice] = l(:notice_risk_activity_successful_create)
      redirect_to risk_path(@risk)
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    @activity.safe_attributes = params[:risk_activity]

    if @activity.save
      flash[:notice] = l(:notice_risk_activity_successful_update)
      redirect_to risk_path(@risk)
    else
      render action: 'edit'
    end
  end

  def destroy
    @activity.destroy
    flash[:notice] = l(:notice_risk_activity_successful_delete)
    redirect_to risk_path(@risk)
  end

  private

  def find_risk
    @risk = Risk.find(params[:risk_id])
    raise Unauthorized unless @risk.visible?
    @project = @risk.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_activity
    @activity = @risk.activities.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_manage_activities
    raise Unauthorized unless User.current.allowed_to?(:manage_risk_activities, @project)
  end
end
