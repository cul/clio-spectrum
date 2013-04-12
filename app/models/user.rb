require 'ipaddr'

class User < ActiveRecord::Base
  include Devise::Models::DatabaseAuthenticatable

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :wind_authenticatable, :encryptable, :authentication_keys => [:login] 
  wind_host "wind.columbia.edu"
  wind_service "culscv"
  # Setup accessible (or protected) attributes for your model

  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :first_name, :last_name, :login

  validates :login, :uniqueness => true, :presence => true
 
  before_validation(:default_email, :on => :create) 
  before_validation(:generate_password, :on => :create) 
  before_create :set_personal_info_via_ldap
  

  COLUMBIA_IP_RANGES = ["128.59.0.0/16", "129.236.0.0/16", "156.111.0.0/16", "156.145.0.0/16", "160.39.0.0/16", "129.12.82.0/24", "192.5.43.0/24", (IPAddr.new("207.10.136.0/24")...IPAddr.new("207.10.144.0/24")), "209.2.47.0/24", (IPAddr.new("209.2.48.0/24")...IPAddr.new("209.2.52.0/24")), "209.2.185.0/24", (IPAddr.new("209.2.208.0/24")...IPAddr.new("209.2.224.0/24")), (IPAddr.new("209.2.224.0/24")...IPAddr.new("209.2.240.0/24")), "127.0.0.1"]


  def self.on_campus?(ip_addr)
    COLUMBIA_IP_RANGES.any? { |ir| ir.kind_of?(Range) ? ir.include?(ip_addr) : IPAddr.new(ir) === ip_addr }
  end



  def has_role?(area, role, admin_okay = true)
    self.login.in?(PERMISSIONS_CONFIG[area][role]) || (admin_okay && self.login.in?(PERMISSIONS_CONFIG['site']['manage']))
  end

  def to_s
    email
  end
  
  def name
    [first_name, last_name].join(" ") 
  end
  def default_email
    login = self.send User.wind_login_field
    mail = "#{login}@columbia.edu"
    self.email = mail
  end

  private

 def default_email
    login = self.send User.wind_login_field
    mail = "#{login}@columbia.edu"
    self.email = mail
  end
  
    
  def generate_password
    self.password = SecureRandom.base64(8)
  end
  
  def set_personal_info_via_ldap
    if wind_login
      entry = Net::LDAP.new({:host => "ldap.columbia.edu", :port => 389}).search(:base => "o=Columbia University, c=US", :filter => Net::LDAP::Filter.eq("uid", wind_login)) || []
      entry = entry.first

      if entry
        _mail = entry[:mail].to_s
        if _mail.length > 6 and _mail.match(/^[\w.]+[@][\w.]+$/)
          self.email = _mail
        else
          self.email = wind_login + '@columbia.edu'
        end
        if User.column_names.include? "last_name"
          self.last_name = entry[:sn].to_s.gsub("[","").gsub("]","").gsub(/\"/,"")
        end
        if User.column_names.include? "first_name"
          self.first_name = entry[:givenname].to_s.gsub("[","").gsub("]","").gsub(/\"/,"")
        end
      end
    end

    return self
  end

end
