require 'ipaddr'
require 'resolv'

class User < ApplicationRecord
  include Cul::Omniauth::Users

  # cul_omniauth includes several options (:registerable, 
  # :recoverable, :rememberable, :trackable, :validatable, ...)
  # but we also want...
  devise :timeoutable

  serialize :affils, Array

  # cul_omniauth sets "devise :recoverable", and that requires
  # that the following user attributes be available.
  attr_accessor :reset_password_token, :reset_password_sent_at

  # # devise requires that a password getter and setter be defined
  # # instead of defining bogus methods below, just use this.
  # attr_accessor :password

  validates :uid, uniqueness: true, presence: true

  before_validation(:default_email, on: :create)
  # before_validation(:generate_password, on: :create)

  # Before first-time User record creation...
  before_create :set_personal_info_via_ldap
  
  # ERROR "UNIQUE constraint failed" - need to figure this out
  # Every user-object instantiation...
  # after_initialize :set_personal_info_via_ldap
  

  def self.on_campus?(ip_addr)
    # check passed string against regexp from standard library
    return false unless ip_addr =~ Resolv::IPv4::Regex

    APP_CONFIG['COLUMBIA_IP_RANGES'].any? do |ir|
      IPAddr.new(ir) === ip_addr
    end
  end

  def has_role?(area, role, admin_okay = true)
    uid && uid.in?(PERMISSIONS_CONFIG[area][role]) ||
      (admin_okay && self.admin?)
  end

  def has_affil(affil = nil)
    return false if affil.blank?
    return false unless affils
    affils.include?(affil)
  end

  def culstaff?
    return true if self.has_affil('CUL_allstaff')
    return true if self.has_affil('CUL_culis')
    # Let our partners in BC and TC use staff-only features
    return true if self.has_affil('CUL_bcpartners')
    return true if self.has_affil('CUL_tcpartners')
    return false
  end

  # developers and sysadmins
  def admin?
    # Anyone in the cunix dpts-dev group is considered an admin
    return true if self.has_affil('CUL_dpts-dev')
    # But, we can also add extra unis as needed via permissions.yml
    uid.in?(PERMISSIONS_CONFIG['site']['manage'])
  end

  # application-level admin permissions
  def valet_admin?
    return true if admin?
    valet_admins = Array(APP_CONFIG['valet_admins']) || []
    return valet_admins.include? uid
  end

  def best_bets_admin?
    # NEXT-1584 - Best Best admins goes of app_config
    return true if admin?
    best_bets_admins = Array(APP_CONFIG['best_bets_admins']) || []
    return best_bets_admins.include? uid
  end

  def to_s
    email
  end

  def name
    [first_name, last_name].join(' ')
  end

  # Password methods required by Devise.
  def password
    Devise.friendly_token[0,20]
  end
  
  def password=(*val)
    # NOOP
  end

  private

  def default_email
    mail = "#{self.uid}@columbia.edu"
    self.email = mail
   end

  # def generate_password
  #   self.password = SecureRandom.base64(8)
  # end

  def set_personal_info_via_ldap
    # Can't proceed without a uid!
    return unless uid

    # This should use Resolv-Replace instead of DNS
    ldap_ip_address = Resolv.getaddress('ldap.columbia.edu')

    entry = Net::LDAP.new(host: ldap_ip_address, port: 389).search(base: 'o=Columbia University, c=US', filter: Net::LDAP::Filter.eq('uid', uid)) || []
    entry = entry.first

    if entry
      _mail = entry[:mail].to_s
      if _mail.length > 6 and _mail.match(/^.+@.+$/)
        self.email = _mail
      else
        self.email = uid + '@columbia.edu'
      end
      if User.column_names.include? 'last_name'
        self.last_name = entry[:sn].to_s.delete('[').delete(']').delete('"')
      end
      if User.column_names.include? 'first_name'
        self.first_name = entry[:givenname].to_s.delete('[').delete(']').delete('"')
      end
    end

    self
  end
end
