class RakeMailer < ApplicationMailer
  default from: 'CLIO <noreply@library.columbia.edu>'
  
  def rake_mail(params)
    mail(params)
  end

end




