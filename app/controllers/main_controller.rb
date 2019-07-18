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

class MainController < ApplicationController
  include Registrar
  
  # GET /
  def index
    # Store invite token
    session[:invite_token] = params[:invite_token] if params[:invite_token] && invite_registration
  end

  # GET /home
  def home
    # Redirection
    if current_user
      redirect_to room_path(current_user.main_room)
    elsif Rails.configuration.omniauth_ldap
      redirect_to "#{relative_root}/ldap_signin"
    else
      # Warning: If you have overriden your root_path with a redirect to
      # this controller ('/home'), you will fall in an infinite
      # redirection loop
      redirect_to root_path 
    end
  end
end
