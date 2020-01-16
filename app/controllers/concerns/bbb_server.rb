# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
#
# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.
#
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

require 'bigbluebutton_api'

module BbbServer
  extend ActiveSupport::Concern
  include BbbApi

  META_LISTED = "gl-listed"

  # Checks if a room is running on the BigBlueButton server.
  def room_running?(bbb_id)
    bbb_server.is_meeting_running?(bbb_id)
  end

  def get_recordings(meeting_id)
    bbb_server.get_recordings(meetingID: meeting_id)
  end

  def get_multiple_recordings(meeting_ids)
    bbb_server.get_recordings(meetingID: meeting_ids)
  end

  # Returns a URL to join a user into a meeting.
  def join_path(room, name, options = {}, uid = nil)
    # Create the meeting, even if it's running
    start_session(room, options)

    # Determine the password to use when joining.
    password = options[:user_is_moderator] ? room.moderator_pw : room.attendee_pw

    # Generate the join URL.
    join_opts = {}
    join_opts[:userID] = uid if uid
    join_opts[:join_via_html5] = true
    join_opts[:guest] = true if options[:require_moderator_approval] && !options[:user_is_moderator]

    bbb_server.join_meeting_url(room.bbb_id, name, password, join_opts)
  end

  # Creates a meeting on the BigBlueButton server.
  def start_session(room, options = {})
    create_options = {
      record: options[:meeting_recorded].to_s,
      logoutURL: options[:meeting_logout_url] || '',
      moderatorPW: room.moderator_pw,
      attendeePW: room.attendee_pw,
      moderatorOnlyMessage: options[:moderator_message],
      muteOnStart: options[:mute_on_start] || false,
      "meta_#{META_LISTED}": options[:recording_default_visibility] || false,
      "meta_bbb-origin-version": Greenlight::Application::VERSION,
      "meta_bbb-origin": "Greenlight",
      "meta_bbb-origin-server-name": options[:host]
    }

    create_options[:guestPolicy] = "ASK_MODERATOR" if options[:require_moderator_approval]

    # Send the create request.
    begin
      meeting = bbb_server.create_meeting(room.name, room.bbb_id, create_options)
      # Update session info.
      unless meeting[:messageKey] == 'duplicateWarning'
       room.update_attributes(sessions: room.sessions + 1,
          last_session: DateTime.now)
      end
    rescue BigBlueButton::BigBlueButtonException => e
      puts "BigBlueButton failed on create: #{e.key}: #{e.message}"
      raise e
    end
  end

  # Gets the number of recordings for this room
  def recording_count(bbb_id)
    bbb_server.get_recordings(meetingID: bbb_id)[:recordings].length
  end

  # Update a recording from a room
  def update_recording(record_id, meta)
    meta[:recordID] = record_id
    bbb_server.send_api_request("updateRecordings", meta)
  end

  # Deletes a recording from a room.
  def delete_recording(record_id)
    bbb_server.delete_recordings(record_id)
  end

  # Deletes all recordings associated with the room.
  def delete_all_recordings(bbb_id)
    record_ids = bbb_server.get_recordings(meetingID: bbb_id)[:recordings].pluck(:recordID)
    bbb_server.delete_recordings(record_ids) unless record_ids.empty?
  end

  # Chooses the recording url of a room, based on its id and type
  # Returns the recording and the url, if it exists
  def play_recording(record_id, type)
    convert_to_transcription = if type == "transcription"
      type = "presentation"
      true
    else
      false
    end
    recording = bbb_server.get_recordings(recordID: record_id)[:recordings].select { |p| p.dig(:playback, :format, :type) == type }.first
    if convert_to_transcription
      return recording, get_transcription_url(recording.dig(:playback, :format, :url), record_id) if recording
    else
      return recording, recording.dig(:playback, :format, :url) if recording
    end
  end

  # Passing token on the url
  def token_url(user, ip, record_id, playback)
    auth_token = get_token(user, ip, record_id)
    uri = playback
    if auth_token.present?
      uri += URI.parse(uri).query.blank? ? "?" : "&"
      uri += "token=#{auth_token}"
    end

    uri
  end

  # Get the token from the server
  def get_token(user, ip, record_id)
    if Rails.configuration.enable_recordings_authentication
      auth_name = user.present? ? user.username : "anonymous"
      api_token = bbb_server.send_api_request("getRecordingToken", authUser: auth_name, authAddr: ip, meetingID: record_id, action: "edit")
      api_token[:token]
    end
  rescue BigBlueButton::BigBlueButtonException => e
    puts "BigBlueButton failed on getRecordingToken: #{e.key}: #{e.message}"
    raise e
  end

  def get_transcription_url(url, record_id)
    uri = URI.parse(url)
    "#{uri.scheme}://#{uri.host}/editor/captions/#{record_id}/edit"
  end
end
