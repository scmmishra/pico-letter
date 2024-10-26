# == Schema Information
#
# Table name: domains
#
#  id            :bigint           not null, primary key
#  dkim_status   :string           default("pending")
#  dmarc_added   :boolean          default(FALSE)
#  error_message :string
#  name          :string
#  public_key    :string
#  region        :string           default("us-east-1")
#  spf_status    :string           default("pending")
#  status        :string           default("pending")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  newsletter_id :bigint           not null
#
# Indexes
#
#  index_domains_on_name           (name) UNIQUE
#  index_domains_on_newsletter_id  (newsletter_id)
#
# Foreign Keys
#
#  fk_rails_...  (newsletter_id => newsletters.id)
#
class Domain < ApplicationRecord
  belongs_to :newsletter

  enum :status, [ :not_started, :pending, :success, :failed, :temporary_failure ], default: :pending
  validates :name, presence: true, uniqueness: true

  def register_identity
    public_key = ses_service.create_identity
    update(public_key: public_key, region: ses_service.region)
    sync_attributes
  end

  def is_verifying
    verification_status == "success" && dkim_status == "success" && spf_details == "success"
  end

  private

  def sync_attributes
    identity = ses_service.get_identity
    update(
      dkim_status: identity.dkim_attributes.status.downcase,
      spf_status: identity.mail_from_attributes.mail_from_domain_status.downcase,
      status: identity.verification_status.downcase
    )
  end

  def ses_service
    @ses_service ||= SES::DomainService.new(name)
  end
end
