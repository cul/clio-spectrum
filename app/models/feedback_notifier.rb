class FeedbackNotifier < ActionMailer::Base
  def send_feedback(params)
    from APP_CONFIG[:email_address]
    subject "#{APP_CONFIG[:application_name]} Feedback from #{params["email"]}"
    recipients APP_CONFIG[:email_address]
    
    @params = params
  end  

end
