class Chat < ApplicationRecord
  has_many :messages, dependent: :destroy

  def openai_messages
    self.messages.map(&:openai_message)
  end
end
