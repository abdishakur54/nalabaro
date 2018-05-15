class RoomsController < ApplicationController

  before_action :find_room, :verify_room_ownership
  skip_before_action :verify_room_ownership, only: [:index, :join, :wait]

  # GET /r/:room_uid
  def index
    opts = default_meeting_options

    if @meeting.is_running?
      if current_user
        # If you don't own the room but the meeting is running, join up.
        if !@room.owned_by?(current_user)
          opts[:user_is_moderator] = false
          redirect_to @meeting.join_path(current_user.name, opts)
        end
      else
        # If you're unauthenticated, you must enter a name to join the meeting.
        redirect_to join_room_path(@room.uid)
      end
    else
      # If the meeting isn't running and you don't own the room, go to the waiting page.
      if !@room.owned_by?(current_user)
        redirect_to wait_room_path(@room.uid)
      end
    end
  end

  # GET /r/:room_uid/start
  def start
    # Join the user in and start the meeting.
    opts = default_meeting_options
    opts[:user_is_moderator] = true
    redirect_to @meeting.join_path(current_user.name, opts)
  end

  # GET /r/:room_uid/join
  def join
    if @meeting.is_running?
      opts = default_meeting_options

      if current_user
        # If the user exists, join them in.
        opts[:user_is_moderator] = @room.owned_by?(current_user)
        redirect_to @meeting.join_path(current_user.name, opts)
      else
        # If they are unauthenticated, prompt for join name.
        if params[:join_name]
          redirect_to @meeting.join_path(params[:join_name], opts)
        else
          # Render the join page so they can supply their name.
          render :join
        end
      end
    else
      if @room.owned_by?(current_user)
        # Redirect owner to room.
        redirect_to room_path(@room.uid)
      else
        # Otherwise, they have to wait for the meeting to start.
        redirect_to wait_room_path(@room.uid)
      end
    end
  end

  # GET /r/:room_uid/wait
  def wait
    if @meeting.is_running?
      if current_user
        # If they are logged in and waiting, use their account name.
        redirect_to @meeting.join_path(current_user.name, default_meeting_options)
      elsif !params[:unauthenticated_join_name].blank?
        # Otherwise, use the name they submitted on the wating page.
        redirect_to @meeting.join_path(params[:unauthenticated_join_name], default_meeting_options)
      end
    end
  end

  # GET /r/:room_uid/logout
  def logout
    # Redirect the owner to their room.
    redirect_to room_path(@room.uid)
  end

  private

  # Find the room from the uid.
  def find_room
    @room = Room.find_by(uid: params[:room_uid])

    if @room.nil?
      # Handle room doesn't exist.

    end

    @meeting = @room.meeting
  end

  # Ensure the user is logged into the room they are accessing.
  def verify_room_ownership
    bring_to_room if !@room.owned_by?(current_user)
  end

  # Redirects a user to their room.
  def bring_to_room
    if current_user
      # Redirect authenticated users to their room.
      redirect_to room_path(current_user.room.uid)
    else
      # Redirect unauthenticated users to root.
      redirect_to root_path
    end
  end
end