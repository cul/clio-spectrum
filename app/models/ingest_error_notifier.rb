class IngestErrorNotifier < ActionMailer::Base
  def generic_error(params = {})
    from "clio.new.arrivals@gmail.com"
    subject "New Arrivals #{Rails.env} Ingest Error "
    recipients "clio-new-arrivals-feedback@libraries.cul.columbia.edu"
    
    @params = params

    @log = IO.popen('tail -n 20 ' + File.join(Rails.root, "log", "#{Rails.env}_ingest.log")).readlines.join
  end  

end
