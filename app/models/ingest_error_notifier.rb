class IngestErrorNotifier < ActionMailer::Base
  def generic_error(params = {})
    from APP_CONFIG[:email_address]
    subject "#{APP_CONFIG[:application_name]} #{Rails.env} Ingest Error "
    recipients APP_CONFIG[:email_address]
    
    @params = params

    @log = IO.popen('tail -n 20 ' + File.join(Rails.root, "log", "#{Rails.env}_ingest.log")).readlines.join
  end  

end
