// Generated by CoffeeScript 1.3.3
var app, sio;

app = require('./src/srv/routes');

sio = require('./src/srv/sockets')(app);
