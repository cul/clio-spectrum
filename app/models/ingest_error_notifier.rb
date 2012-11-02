class IngestErrorNotifier < ActionMailer::Base
  def generic_error(params = {})
    
    @params = params

    @log = IO.popen('tail -n 20 ' + File.join(Rails.root, "log", "#{Rails.env}_ingest.log")).readlines.join

    mail(:to => APP_CONFIG['email_address'], :from => APP_CONFIG['email_address'], :subject => subject)
  end  

end
