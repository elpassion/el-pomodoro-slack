require 'rubygems'
require 'bundler/setup'

require_groups = [:default, ENV['RACK_ENV']].compact
Bundler.require(*require_groups)
Dotenv.load if defined?(Dotenv)

require 'pp'
require 'json'

require './storage'
require './slack_client'

def client(access_token)
  SlackClient.new(access_token).get
end

storage = Storage.new

storage.get_users.each do |user_id, user_data|
  client = client(user_data.fetch('access_token'))
  ims = client.im_list.ims
  ims.each do |channel|
    puts "Downloading for [#{channel.id}]..."
    history = client.im_history(channel: channel.id, count: 1, unreads: 1)
    return if history.messages.empty?
    last_message = history.messages.last
    last_message_user = last_message.user
    # post_message if unread pending and last_message_user is_interlocutor?
    if history.unread_count_display > 0 && last_message_user == channel.user
      puts "sending message to channel #{channel.id}, user: #{last_message_user}"
      client.chat_postMessage(channel: channel.id, text: 'This is ElPomodoro Slack App test!', as_user: true)
    end
  end
end
