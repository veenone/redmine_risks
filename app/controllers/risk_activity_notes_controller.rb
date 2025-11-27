class RiskActivityNotesController < ApplicationController
  before_action :find_risk_and_activity
  before_action :authorize_manage_activities

  helper :risks
  include RisksHelper

  def create
    @note = @activity.notes.build
    @note.author = User.current
    @note.content = params[:risk_activity_note][:content]

    if @note.save
      flash[:notice] = l(:notice_risk_activity_note_successful_create)
    else
      flash[:error] = l(:error_risk_activity_note_create_failed)
    end

    redirect_to risk_activity_path(@risk, @activity)
  end

  def destroy
    @note = @activity.notes.find(params[:id])

    if @note.editable? && @note.destroy
      flash[:notice] = l(:notice_risk_activity_note_successful_delete)
    else
      flash[:error] = l(:error_risk_activity_note_delete_failed)
    end

    redirect_to risk_activity_path(@risk, @activity)
  end

  private

  def find_risk_and_activity
    @risk = Risk.find(params[:risk_id])
    @activity = @risk.activities.find(params[:activity_id])
    raise Unauthorized unless @risk.visible?
    @project = @risk.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_manage_activities
    raise Unauthorized unless User.current.allowed_to?(:manage_risk_activities, @project)
  end
end
