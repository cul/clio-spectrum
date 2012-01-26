class FeedbackNotifier < ActionMailer::Base
  def send_feedback(params)
    subject = "#{APP_CONFIG[:application_name]} Feedback from #{params["email"]}"
    
    @params = params

    mail(:to => APP_CONFIG[:email_address], :from => APP_CONFIG[:email_address], :subject => subject)
  end  

end
