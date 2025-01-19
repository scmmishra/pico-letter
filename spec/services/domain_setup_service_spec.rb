require 'rails_helper'

RSpec.describe DomainSetupService do
  describe "Registring an invalid domain" do
    let!(:newsletter) { create(:newsletter) }

    it "throws an error" do
      sending_params = { reply_to: "reply_to@invalid", sending_address: "sending_address@invalid" }
      domain_setup = DomainSetupService.new(newsletter, sending_params)
      expect { domain_setup.perform }.to raise_error("Domain name invalid")
    end
  end

  describe "Registring already registered domain" do
    let!(:user) { create(:user) }
    let!(:newsletter) { create(:newsletter, user_id: user.id) }
    let!(:another_newsletter) { create(:newsletter, user_id: user.id) }
    let!(:domain) { create(:domain, name: 'example.com',  newsletter_id: another_newsletter.id, status: "success", dkim_status: "success", spf_status: "success") }
    let(:sending_params) { { reply_to: "test@example.com", sending_address: "test@example.com" } }

    it 'throws an error' do
      domain_setup = DomainSetupService.new(newsletter, sending_params)
      expect { domain_setup.perform }.to raise_error("Domain already in use")
    end
  end

  describe "Fresh domain setup" do
    let!(:user) { create(:user, email: 'fresh-service@example.com') }
    let!(:newsletter) { create(:newsletter, slug: 'fresh-newsletter', user_id: user.id) }
    let(:sending_params) { { reply_to: "hey@example.com", sending_address: "hey@example.com" } }

    let(:mock_ses_service) { double("SES::DomainService") }
    let(:mock_identity_response) do
      double(
        dkim_attributes: double(status: 'SUCCESS'),
        mail_from_attributes: double(mail_from_domain_status: 'SUCCESS'),
        verification_status: 'SUCCESS'
      )
    end

    before do
      allow(SES::DomainService).to receive(:new).and_return(mock_ses_service)
      allow(mock_ses_service).to receive(:create_identity).and_return('mock-public-key')
      allow(mock_ses_service).to receive(:get_identity).and_return(mock_identity_response)
      allow(mock_ses_service).to receive(:region).and_return('us-east-1')
    end

    it 'creates a new identity and syncs the status' do
      domain_setup = DomainSetupService.new(newsletter, sending_params)
      domain_setup.perform

      # Check that the newsletter was updated
      expect(newsletter.reload.reply_to).to eq('hey@example.com')
      expect(newsletter.sending_address).to eq('hey@example.com')

      # Check that the domain was created
      domain = Domain.find_by(newsletter: newsletter)
      expect(domain).to be_present
      expect(domain.name).to eq('example.com')
      expect(domain.public_key).to eq('mock-public-key')
      expect(domain.region).to eq('us-east-1')

      # Check domain status
      expect(domain.status).to eq('success')
      expect(domain.dkim_status).to eq('success')
      expect(domain.spf_status).to eq('success')

      # Verify SES service calls
      expect(mock_ses_service).to have_received(:create_identity)
      expect(mock_ses_service).to have_received(:get_identity)
    end

    context "when SES service fails" do
      before do
        allow(mock_ses_service).to receive(:create_identity).and_raise(StandardError.new("AWS SES Error"))
      end

      it 'rolls back the transaction' do
        domain_setup = DomainSetupService.new(newsletter, sending_params)

        expect {
          domain_setup.perform
        }.to raise_error(StandardError, "AWS SES Error")

        expect(Domain.find_by(newsletter: newsletter)).to be_nil
        expect(newsletter.reload.sending_address).not_to eq('hey@example.com')
      end
    end
  end

  describe "Has existing domain" do
  end

  describe "Re-registring same domain" do
  end
end
