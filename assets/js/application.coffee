socket = io.connect()

messages = []
ownMessages = []

typingNotice = '<span>typing...</span>'

checkTyping = =>
  if $("#typing-box").val() != ""
    $("#typing-box").unbind "keypress"
    socket.emit("typing")
    setTimeout(
      =>
        $("#typing-box").bind "keypress", checkTyping
      , 1500
    )

showMessage = =>
  message = messages[messages.length - 1]
  return unless $("#message").html().toLowerCase() in ["", typingNotice] and message

  messages.pop()

  $("#message").html(message)
  setTimeout(
    =>
      $("#message").html("")
      showMessage()
    , 3000
  )

showTyping = =>
  return unless $("#message").html() == ""

  $("#message").html(typingNotice)
  setTimeout(
    =>
      $("#message").html("") if $("#message").html().toLowerCase() == typingNotice
      showMessage()
    , 1500
  )

showOwnMessage = =>
  message = ownMessages[ownMessages.length - 1]
  return unless $("#own-message").html() == "" and message

  ownMessages.pop()

  $("#own-message").html(message)
  setTimeout(
    =>
      $("#own-message").html("")
      showOwnMessage()
    , 3000
  )


window.socket = socket

socket.on 'room available', (room) => socket.emit 'join room', room

socket.on 'room ready', (room) =>
  socket.emit "leave waiting room"
  $("#loading").hide()
  $("#chat").show()
  $("#message").html "<span>Say hi!</span>"
  $("#typing-box").focus()
  setTimeout(
    =>
      $("#message").html("")
      showMessage()
    , 3000
  )


socket.on 'room lost', (room) =>
  socket.emit 'join waiting room'
  $("#loading").show()
  $("#chat").hide()

socket.on 'message', (message) =>
  messages.push message
  showMessage()

socket.on 'typing', (message) =>
  console.log "typing..."
  showTyping()

socket.emit 'join waiting room'

$(document).ready =>
  $("#typing").submit =>
    message = $("#typing-box").val()
    socket.emit 'message', message
    ownMessages.push message
    showOwnMessage()
    $("#typing-box").val("")
    false
  $("#typing-box").bind "keypress", checkTyping