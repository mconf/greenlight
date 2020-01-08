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
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>

class RecordingsController < ApplicationController
  layout false

  before_action :find_room
  before_action :verify_room_ownership, except: :play

  META_LISTED = "gl-listed"

  # GET /:meetingID/:record_id/:format
  def play
    recording, url = play_recording(params[:record_id], params[:type])

    # If it is private, and it is not the owner, can't access recording
    redirect_to unauthorized_path if @room.owner != current_user &&
                                     recording &&
                                     recording[:metadata][:'gl-listed'] == 'private'

    @token_url = token_url(current_user,
      Rails.configuration.fake_user_address || request.env['HTTP_X_FORWARDED_FOR'] || request.remote_ip,
      params[:record_id],
      url)
  end

  # POST /:meetingID/:record_id
  def update
    meta = {
      "meta_#{META_LISTED}" => params[:state],
    }

    res = update_recording(params[:record_id], meta)

    # Redirects to the page that made the initial request
    redirect_back fallback_location: root_path if res[:updated]
  end

  # PATCH /:meetingID/:record_id
  def rename
    update_recording(params[:record_id], "meta_name" => params[:record_name])

    redirect_back fallback_location: room_path(@room)
  end

  # DELETE /:meetingID/:record_id
  def delete
    delete_recording(params[:record_id])

    # Redirects to the page that made the initial request
    redirect_back fallback_location: root_path
  end

  private

  def find_room
    @room = Room.find_by!(bbb_id: params[:meetingID])
  end

  # Ensure the user is logged into the room they are accessing.
  def verify_room_ownership
    if !current_user || (!@room.owned_by?(current_user) &&
           !current_user.highest_priority_role.get_permission("can_edit_site_settings") &&
           !current_user.has_role?(:super_admin))
      redirect_to root_path
    end
  end
end
