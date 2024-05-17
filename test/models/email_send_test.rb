# == Schema Information
#
# Table name: email_sends
#
#  id         :integer          not null, primary key
#  status     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  email_id   :string
#  post_id    :integer          not null
#
# Indexes
#
#  index_email_sends_on_post_id  (post_id)
#
# Foreign Keys
#
#  post_id  (post_id => posts.id)
#
require "test_helper"

class EmailSendTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
