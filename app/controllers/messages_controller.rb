class MessagesController < ApplicationController
  include ActionView::RecordIdentifier

  def create
    @message = Message.create(
      params.require(:message)
            .permit(:content)
            .merge(chat_id: params[:chat_id], role: "user")
    )

    @message.broadcast_prepend_to(
      "#{dom_id(@message.chat)}_messages",
      target: "#{dom_id(@message.chat)}_messages",
      partial: "messages/message",
      locals: { dom_id: dom_id(@message), role: @message.role, content: @message.content }
    )

    MessageStreamJob.perform_later(@message.chat_id)

    respond_to do |format|
      format.turbo_stream
    end
  end
end
