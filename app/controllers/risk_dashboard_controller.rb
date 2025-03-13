class RiskDashboardController < ApplicationController
    before_action :find_project_by_project_id, :authorize, :only => [:project]
    before_action :require_admin, :only => [:index]
    
    helper :risks
    include RisksHelper
    
    def index
      # Show dashboard for all projects (admin only)
      @projects = Project.visible.has_module(:risks).order(:name)
      
      # Get risks statistics for all visible projects
      @total_risks = Risk.joins(:project).where(projects: { status: Project::STATUS_ACTIVE }).count
      @open_risks = Risk.where(closed_on: nil).joins(:project).where(projects: { status: Project::STATUS_ACTIVE }).count
      @closed_risks = Risk.where.not(closed_on: nil).joins(:project).where(projects: { status: Project::STATUS_ACTIVE }).count
      
      # Risks by probability and impact
      @risks_by_probability = Risk.joins(:project).where(projects: { status: Project::STATUS_ACTIVE })
                                   .group(:probability).count.transform_keys { |k| k || 0 }
      @risks_by_impact = Risk.joins(:project).where(projects: { status: Project::STATUS_ACTIVE })
                             .group(:impact).count.transform_keys { |k| k || 0 }
      
      # Risks by status
      @risks_by_status = Risk.joins(:project).where(projects: { status: Project::STATUS_ACTIVE }).group(:status).count
      
      # Risks by strategy
      @risks_by_strategy = Risk.joins(:project).where(projects: { status: Project::STATUS_ACTIVE }).group(:strategy).count
      
      # Recent risks
      @recent_risks = Risk.joins(:project).where(projects: { status: Project::STATUS_ACTIVE })
                          .order(created_on: :desc).limit(10)
      
      render 'dashboard/index'
    end
    
    def project
      # Show dashboard for a specific project
      retrieve_query(RiskQuery)
      
      # Use the association if it exists, otherwise use direct Risk query
      if @project.respond_to?(:risks)
        project_risks = @project.risks
      else
        project_risks = Risk.where(project_id: @project.id)
      end
      
      @total_risks = project_risks.count
      @open_risks = project_risks.where(closed_on: nil).count
      @closed_risks = project_risks.where.not(closed_on: nil).count
      
      # Risks by probability and impact
      @risks_by_probability = project_risks.group(:probability).count.transform_keys { |k| k || 0 }
      @risks_by_impact = project_risks.group(:impact).count.transform_keys { |k| k || 0 }
      
      # Risk probability/impact matrix
      @risk_matrix = {}
      
      # Initialize matrix with empty values
      Risk::RISK_PROBABILITY.count.times do |p|
        @risk_matrix[p] = {}
        Risk::RISK_IMPACT.count.times do |i|
          @risk_matrix[p][i] = []
        end
      end
      
      # Fill matrix with risks
      project_risks.each do |risk|
        next unless risk.probability && risk.impact
        
        p_index = risk.probability / 25  # 0, 25, 50, 75, 100 -> 0, 1, 2, 3, 4
        i_index = risk.impact / 25       # 0, 25, 50, 75, 100 -> 0, 1, 2, 3, 4
        
        @risk_matrix[p_index][i_index] << risk
      end
      
      # Risks by status
      @risks_by_status = project_risks.group(:status).count
      
      # Risks by strategy
      @risks_by_strategy = project_risks.group(:strategy).count.reject { |k, _| k.nil? }
      
      # Recent risks
      @recent_risks = project_risks.order(created_on: :desc).limit(5)
      
      # Top risks by magnitude - using safe SQL with Arel.sql
      require 'arel'
      @top_risks = project_risks.where(closed_on: nil)
                           .where.not(probability: nil)
                           .where.not(impact: nil)
                           .order(Arel.sql('probability * impact DESC'))
                           .limit(5)
      
      render 'dashboard/project'
    end
  end