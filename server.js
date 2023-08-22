const express = require('express');

let socket = require('socket.io');
let app = express();
let server = app.listen(4000);
app.use(express.static('public'));
let io = socket(server);

io.on('connection', (socket) => {
  console.log('made socket connection', socket.id);
  socket.on('pixels', (data) => {
    console.log(data);
    socket.broadcast.emit('pixels', data);
  });
});