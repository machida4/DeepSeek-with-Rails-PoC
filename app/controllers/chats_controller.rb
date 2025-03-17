class ChatsController < ApplicationController
  def show
    @chat = Chat.first

    if @chat.blank?
      @chat = Chat.create!
    end
  end
end
