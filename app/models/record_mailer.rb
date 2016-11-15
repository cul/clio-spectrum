# -*- encoding : utf-8 -*-

# Despite living under /app/models, this is not a Model, it's a Mailer.
class RecordMailer < ActionMailer::Base

  default from: 'CLIO <noreply@library.columbia.edu>'

  add_template_helper(ApplicationHelper)
  add_template_helper(DisplayHelper)
  add_template_helper(MarcHelper)
  add_template_helper(CulCatalogHelper)
  add_template_helper(HoldingsHelper)
  add_template_helper(ArticlesHelper)

  def email_record(documents, details, url_gen_params)
    # raise
    if documents.size == 1
      title_for_subject = if documents.first.kind_of?(Summon::Document)
        documents.first.title
      elsif documents.first.has_key?('title_display')
        documents.first['title_display'].first
      else
        'Single Item'
      end
      subject = "CLIO: #{title_for_subject rescue 'N/A'}"
    else
      subject = "CLIO: #{documents.size} Item Records"
    end

    @documents      = documents
    @message        = details[:message]
    @url_gen_params = url_gen_params

    # Action Mailer base method, uses corresponding view to generate text of the messgae
    mail(to: details[:to], reply_to: details[:reply_to], subject: subject)
  end

  # def OLD_sms_record(documents, details, url_gen_params)
  #   if sms_mapping[details[:carrier]]
  #     to = "#{details[:to]}@#{sms_mapping[details[:carrier]]}"
  #   end
  # 
  #   @documents      = documents
  #   @host           = 'libraries.cul.columbia.edu'
  #   @url_gen_params = url_gen_params
  # 
  #   mail(to: to, subject: '')
  # end

  # BL 6
  def sms_record(documents, details, url_gen_params)
    @documents      = documents
    @url_gen_params = url_gen_params
    mail(:to => details[:to], :subject => "")
  end

  # protected
  # 
  # def OLD_sms_mapping
  #   { 'virgin' => 'vmobl.com',
  #     'att'     => 'txt.att.net',
  #     'verizon' => 'vtext.com',
  #     'nextel'  => 'messaging.nextel.com',
  #     'sprint'  => 'messaging.sprintpcs.com',
  #     'tmobile' => 'tmomail.net',
  #     'alltel'  => 'message.alltel.com',
  #     'cricket' => 'mms.mycricket.com' }
  # end
end
