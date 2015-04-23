express = require('express')
sio     = require('socket.io')
http    = require('http')

app     = express()
port    = process.env.PORT || 3000
server  = app.listen port
io      = sio.listen server

app.configure =>
  app.use require('connect-assets')()
  app.use express.static(__dirname + '/public')
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'

app.get '/', (req, res) =>
    res.render 'index'

app.post '/', (req, res) =>
    res.render 'index'

io.configure =>
  io.set "transports", ["xhr-polling"]
  io.set "polling duration", 20


leave_all_rooms = (socket) =>
  for old_room, value of io.sockets.manager.roomClients[socket.id]
    socket.leave old_room[1..-1]

private_room = (socket) =>
  for room, value of io.sockets.manager.roomClients[socket.id]
    return room[1..-1] unless room in ['', '/waiting_room']

io.sockets.on 'connection', (socket) =>

  socket.on 'join waiting room', =>
    room = Math.random().toString()[2..-1]
    leave_all_rooms(socket)
    socket.join('waiting_room')
    socket.join(room)
    socket.broadcast.to("waiting_room").emit 'room available', room

  socket.on 'leave waiting room', =>
    socket.leave('waiting_room')

  socket.on 'join room', (room) =>
    if io.sockets.manager.rooms["/#{room}"].length < 2
      socket.leave(private_room(socket))
      socket.join(room)
      io.sockets.in(room).emit 'room ready', room

  socket.on 'message', (message) =>
    socket.broadcast.to(private_room(socket)).emit "message", message

  socket.on 'typing', (message) =>
    socket.broadcast.to(private_room(socket)).emit "typing", message

  socket.on 'disconnect', () =>
    socket.broadcast.to(private_room(socket)).emit "room lost" if private_room(socket)