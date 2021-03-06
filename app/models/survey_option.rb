class SurveyOption < ActiveRecord::Base

  serialize :metadata
  belongs_to :survey_question
  belongs_to :survey_page
  belongs_to :survey_iteration

  scope :published_to_sg, -> { where('survey_options.sg_option_id IS NOT NULL') }
  scope :not_published_to_sg, -> { where('survey_options.sg_option_id IS NULL') }

  def sg_option
    return unless self.sg_option_id.present?
    SurveyGizmo::API::Option.first id: self.sg_option_id,
      question_id: self.survey_question.sg_question_id,
      page_id: self.survey_page.sg_page_id,
      survey_id: self.survey_iteration.sg_survey_id
  end
  def sg_option_params
    {
      :survey_id => self.survey_iteration.sg_survey_id,
      :page_id => self.survey_page.sg_page_id,
      :question_id => self.survey_question.sg_question_id,
      :title => self.title,
      :value => self.reporting_value
    }.dup.merge(metadata.present? ? metadata[:sg_params] || {} : {})
  end
  def export_to_survey_gizmo!
    return false if survey_iteration.publish_to_sg_cancelled?
    puts "Exporting survey option!"
    option = SurveyGizmo::API::Option.create sg_option_params
    if self.new_record? then self.sg_option_id = option.id
    else self.update_column(:sg_option_id, option.id) end
  end
  def delete_from_survey_gizmo!
    return false unless self.sg_option.present?
    puts "Deleting option from Survey Gizmo!"
    self.sg_option.destroy
    return true if new_record?
    self.sg_option_id = nil
    self.save
  end

end
