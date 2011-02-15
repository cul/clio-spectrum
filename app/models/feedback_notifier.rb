class FeedbackNotifier < ActionMailer::Base
  def send_feedback(params)
    from "clio_new_arrivals@columbia.edu"
    subject "New Arrivals Feedback from #{params["email"]}"
    recipients "james.stuart@gmail.com"
    
    @params = params
  end  

end
