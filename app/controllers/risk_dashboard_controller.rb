class RiskDashboardController < ApplicationController
  before_action :find_project_by_project_id, :authorize, :only => [:project]
  before_action :require_admin, :only => [:index]
  
  helper :risks
  include RisksHelper
  
  def index
    # Show dashboard for all projects (admin only)
    @projects = Project.visible.has_module(:risks).order(:name)
    
    # Get risks statistics for all visible projects
    visible_risks = Risk.joins(:project).where(projects: { status: Project::STATUS_ACTIVE })
    @total_risks = visible_risks.count
    @open_risks = visible_risks.where(closed_on: nil).count
    @closed_risks = visible_risks.where.not(closed_on: nil).count
    
    # Risks by probability and impact
    @risks_by_probability = visible_risks.group(:probability).count.transform_keys { |k| k || 0 }
    @risks_by_impact = visible_risks.group(:impact).count.transform_keys { |k| k || 0 }
    
    # Risks by status
    @risks_by_status = visible_risks.group(:status).count
    
    # Risks by strategy
    @risks_by_strategy = visible_risks.group(:strategy).count
    
    # Recent risks
    @recent_risks = visible_risks.order(created_on: :desc).limit(10)
    
    # CIA distribution data for charts
    cia_data = prepare_cia_data(visible_risks)
    @risks_by_confidentiality = cia_data[:confidentiality]
    @risks_by_integrity = cia_data[:integrity]
    @risks_by_availability = cia_data[:availability]

    # Risk significance data
    @avg_significance = visible_risks.where.not(level_of_significance: nil)
                                    .average(:level_of_significance)
    @max_significance = visible_risks.maximum(:level_of_significance)

    # Top risks by significance
    @top_risks_by_significance = visible_risks.where(closed_on: nil)
                                             .where.not(level_of_significance: nil)
                                             .order(level_of_significance: :desc)
                                             .limit(5)
    
    render 'dashboard/index'
  end
  
  def project
    # Show dashboard for a specific project
    retrieve_query(RiskQuery)
    
    # Use the association if it exists, otherwise use direct Risk query
    project_risks = @project.respond_to?(:risks) ? @project.risks : Risk.where(project_id: @project.id)
    
    @total_risks = project_risks.count
    @open_risks = project_risks.where(closed_on: nil).count
    @closed_risks = project_risks.where.not(closed_on: nil).count
    
    # Risks by probability and impact
    @risks_by_probability = project_risks.group(:probability).count.transform_keys { |k| k || 0 }
    @risks_by_impact = project_risks.group(:impact).count.transform_keys { |k| k || 0 }
    
    # Risk probability/impact matrix
    @risk_matrix = initialize_risk_matrix
    
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
    
    # CIA distribution data for charts - Using the helper method
    cia_data = prepare_cia_data(project_risks)
    @risks_by_confidentiality = cia_data[:confidentiality]
    @risks_by_integrity = cia_data[:integrity]
    @risks_by_availability = cia_data[:availability]

    # Risk significance data
    @avg_significance = project_risks.where.not(level_of_significance: nil).average(:level_of_significance)
    @max_significance = project_risks.maximum(:level_of_significance)

    # Top risks by significance
    @top_risks_by_significance = project_risks.where(closed_on: nil)
                                             .where.not(level_of_significance: nil)
                                             .order(level_of_significance: :desc)
                                             .limit(5)
    
    render 'dashboard/project'
  end

  private
  
  # Helper method to prepare CIA data with all possible values
  def prepare_cia_data(risks)
    # Initialize with all possible values (0, 1, 2) set to zero count
    confidentiality = {0 => 0, 1 => 0, 2 => 0}
    integrity = {0 => 0, 1 => 0, 2 => 0}
    availability = {0 => 0, 1 => 0, 2 => 0}
    
    # Get actual counts
    conf_counts = risks.group(:confidentiality).count
    int_counts = risks.group(:integrity).count
    avail_counts = risks.group(:availability).count
    
    # Merge in actual counts, handling nil values
    conf_counts.each { |k, v| confidentiality[k.nil? ? 0 : k] = v }
    int_counts.each { |k, v| integrity[k.nil? ? 0 : k] = v }
    avail_counts.each { |k, v| availability[k.nil? ? 0 : k] = v }
    
    return {
      confidentiality: confidentiality,
      integrity: integrity,
      availability: availability
    }
  end
  
  # Initialize an empty risk matrix
  def initialize_risk_matrix
    matrix = {}
    
    Risk::RISK_PROBABILITY.count.times do |p|
      matrix[p] = {}
      Risk::RISK_IMPACT.count.times do |i|
        matrix[p][i] = []
      end
    end
    
    matrix
  end
end