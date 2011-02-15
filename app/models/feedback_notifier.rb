class FeedbackNotifier < ActionMailer::Base
  def send_feedback(params)
    from "clio.new.arrivals@gmail.com"
    subject "New Arrivals Feedback from #{params["email"]}"
    recipients "clio-new-arrivals-feedback@libraries.cul.columbia.edu"
    
    @params = params
  end  

end
