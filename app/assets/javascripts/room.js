// BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
//
// Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
//
// This program is free software; you can redistribute it and/or modify it under the
// terms of the GNU Lesser General Public License as published by the Free Software
// Foundation; either version 3.0 of the License, or (at your option) any later
// version.
//
// BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License along
// with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

// Room specific js for copy button and email link.
$(document).on('turbolinks:load', function(){
  var controller = $("body").data('controller');
  var action = $("body").data('action');

  // Only run on room pages.
  if (controller == "rooms" && action == "show"){
    var copy = $('#copy');

    // Handle copy button.
    copy.on('click', function(){
      var inviteURL = $('#invite-url');
      inviteURL.select();

      var success = document.execCommand("copy");
      if (success) {
        inviteURL.blur();
        copy.addClass('btn-success');
        copy.html("<i class='fas fa-check'></i> Copy")
        setTimeout(function(){
          copy.removeClass('btn-success');
          copy.html("<i class='fas fa-copy'></i> Copy")
        }, 2000)
      }
    });

    // Handle recording emails.
    $('.email-link').each(function(){
      $(this).click(function(){
        var subject = $(".username").text() + " " + t('room.mailer.subject');
        var body =  t('room.mailer.body') + $(this).attr("data-pres-link");
        var footer = t('room.mailer.footer');
        var url = "mailto:?subject=" + encodeURIComponent(subject) + "&body=" + encodeURIComponent(body) + encodeURIComponent(footer);
        var win = window.open(url, '_blank');

        win.focus();
      });
    });
  }

  // Display and update all fields related to creating a room in the createRoomModal
  $("#create-room").click(function(){
    $("#create-room-name").val("")
    $("#createRoomModal form").attr("action", $("body").data('relative-root'))
    updateDropdown($(".dropdown-item[value='default']"))
    $("#room_mute_on_join").prop("checked", false)

    //show all elements & their children with a create-only class
    $(".create-only").each(function() {
      $(this).show()
      if($(this).children().length > 0) $(this).children().show()
    })

    //hide all elements & their children with a update-only class
    $(".update-only").each(function() {
      $(this).attr('style',"display:none !important")
      if($(this).children().length > 0) $(this).children().attr('style',"display:none !important")
    })
  })

  // Display and update all fields related to creating a room in the createRoomModal
  $(".update-room").click(function(){
    var room_block_uid = $(this).closest("#room-block").data("room-uid")
    $("#create-room-name").val($(this).closest("tbody").find("#room-name h4").text())
    $("#createRoomModal form").attr("action", room_block_uid + "/update_settings")

    //show all elements & their children with a update-only class
    $(".update-only").each(function() {
      $(this).show()
      if($(this).children().length > 0) $(this).children().show()
    })

    //hide all elements & their children with a create-only class
    $(".create-only").each(function() {
      $(this).attr('style',"display:none !important")
      if($(this).children().length > 0) $(this).children().attr('style',"display:none !important")
    })

    updateCurrentSettings($(this).closest("#room-block").data("room-settings"))
  })

  //Update the createRoomModal to show the correct current settings
  function updateCurrentSettings(settings){
    //set checkbox
    if(settings.muteOnStart){
      $("#room_mute_on_join").prop("checked", true)
    } else { //default option
      $("#room_mute_on_join").prop("checked", false)
    }

    //set dropdown value
    if (settings.joinViaHtml5) {
      updateDropdown($(".dropdown-item[value='html5']"))
    } else if (settings.joinViaHtml5 == false) {
      updateDropdown($(".dropdown-item[value='flash']"))
    } else { //default option
      updateDropdown($(".dropdown-item[value='default']"))
    }
  }
});

// Updates the dropdown element to show the clicked/correct text
function updateDropdown(element) {
  $("#dropdown-trigger").text(element.text())
  $("#room_client").val(element.val())
}
