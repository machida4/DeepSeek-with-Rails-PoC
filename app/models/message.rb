class Message < ApplicationRecord
  enum :role, {
    system: 0,
    assistant: 1,
    user: 2
  }

  belongs_to :chat

  def openai_message
    {
      role: role,
      content: content
    }
  end
end
