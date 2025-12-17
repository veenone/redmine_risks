class RiskProjectSetting < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :pdf_logo_attachment, class_name: 'Attachment', optional: true

  # CIA Assessment modes
  CIA_MODE_LEVELS = 'levels'.freeze    # Low/Medium/High
  CIA_MODE_BOOLEAN = 'boolean'.freeze  # Yes/No

  CIA_MODES = [CIA_MODE_LEVELS, CIA_MODE_BOOLEAN].freeze

  # Allowed logo file extensions
  ALLOWED_LOGO_EXTENSIONS = %w[png jpg jpeg gif bmp].freeze

  validates :project_id, presence: true, uniqueness: true
  validates :cia_assessment_mode, inclusion: { in: CIA_MODES }

  safe_attributes 'cia_assessment_mode',
                  'pdf_logo_path',
                  'pdf_product_name',
                  'pdf_show_generated_time',
                  'pdf_show_logo',
                  'pdf_show_product_name'

  # Handle logo file upload
  def pdf_logo_file=(file)
    return if file.blank? || file.size == 0

    # Validate file extension
    extension = File.extname(file.original_filename).downcase.delete('.')
    unless ALLOWED_LOGO_EXTENSIONS.include?(extension)
      errors.add(:pdf_logo_file, :invalid_extension)
      return
    end

    # Delete old attachment if exists
    pdf_logo_attachment&.destroy

    # Create new attachment
    attachment = Attachment.new(file: file)
    attachment.author = User.current
    attachment.filename = file.original_filename
    attachment.content_type = file.content_type

    if attachment.save
      self.pdf_logo_attachment = attachment
      self.pdf_logo_path = nil # Clear manual path when uploading file
    else
      errors.add(:pdf_logo_file, attachment.errors.full_messages.join(', '))
    end
  end

  # Delete the uploaded logo
  def delete_pdf_logo
    if pdf_logo_attachment
      pdf_logo_attachment.destroy
      self.pdf_logo_attachment_id = nil
      save
    end
  end

  # Find or initialize settings for a project
  def self.for_project(project)
    find_or_initialize_by(project: project)
  end

  # Check if using boolean (Yes/No) mode
  def boolean_cia_mode?
    cia_assessment_mode == CIA_MODE_BOOLEAN
  end

  # Check if using levels (Low/Medium/High) mode
  def levels_cia_mode?
    cia_assessment_mode == CIA_MODE_LEVELS
  end

  # PDF Report settings helpers
  def pdf_logo_file_path
    return nil unless pdf_show_logo?

    # First check for uploaded attachment
    if pdf_logo_attachment.present?
      return pdf_logo_attachment.diskfile
    end

    # Fall back to manual path if set
    return nil unless pdf_logo_path.present?

    # Allow relative paths from Redmine root or absolute paths
    path = pdf_logo_path.strip
    if path.start_with?('/')
      path
    else
      Rails.root.join(path).to_s
    end
  end

  def pdf_logo_exists?
    path = pdf_logo_file_path
    path.present? && File.exist?(path)
  end

  def has_uploaded_logo?
    pdf_logo_attachment.present?
  end

  def pdf_show_logo?
    pdf_show_logo == true
  end

  def pdf_show_product_name?
    pdf_show_product_name == true
  end

  def pdf_show_generated_time?
    pdf_show_generated_time != false
  end
end
