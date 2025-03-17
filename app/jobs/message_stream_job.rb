class MessageStreamJob < ApplicationJob
  include ActionView::RecordIdentifier

  queue_as :default

  def perform(chat_id)
    chat = Chat.find(chat_id)
    call!(chat: chat)
  end

  private

  def call!(chat:)
    assistant_message = chat.messages.create!(
      role: "assistant",
      content: ""
    )

    assistant_message.broadcast_prepend_later_to(
      "#{dom_id(chat)}_messages",
      target: "#{dom_id(chat)}_messages",
      partial: "messages/message",
      locals: { dom_id: dom_id(assistant_message), role: assistant_message.role, content: assistant_message.content }
    )

    openai_client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: chat.openai_messages,
        temperature: 0.7,
        stream: stream_message(message: assistant_message)
      }
    )
  end

  def stream_message(message:)
    proc do |chunk|
      if is_finished?(chunk)
        message.save!
        next
      end

      message.content += extract_fragment(chunk)

      message.broadcast_append_later_to(
        "#{dom_id(message.chat)}_messages",
        target: "#{dom_id(message.chat)}_messages",
        partial: "messages/message",
        locals: { dom_id: dom_id(message), role: message.role, content: message.content }
      )
    end
  end

  def extract_fragment(chunk)
    chunk.dig("choices", 0, "delta", "content")
  end

  def is_finished?(chunk)
    chunk.dig("choices", 0, "finish_reason").present?
  end

  def openai_client
    @_openai_client ||= OpenAI::Client.new(
      access_token: ENV.fetch("OPENAI_ACCESS_TOKEN"),
      log_errors: true
    )
  end
end
