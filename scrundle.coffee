
express = require 'express'
store = new express.session.MemoryStore()
util = require 'util'
ck = require 'coffeekup'
_ = require 'underscore'
db = require './src/srv/db'
User = db.User
Script = db.Script
mongoose = db.mongoose
Bundler = require './src/srv/bundler'
io = require 'socket.io'

mongooseAuth = require 'mongoose-auth'

app = express.createServer()
sio = io.listen app

app.configure ->
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session {secret: 'keyboardCat', key: 'express.sid', store: store}
  app.use express.bodyParser()
  app.use mongooseAuth.middleware()
  app.use express.static "#{__dirname}/pub"
  app.set 'views', "#{__dirname}/src/views"
  app.set 'view options', { layout: false }
  app.set 'view engine', 'coffee'
  app.register '.coffee', require('coffeekup').adapters.express
  app.use express.errorHandler()

mongooseAuth.helpExpress(app)


app.get '/', (req,res)->
  res.render 'index', {user: req.user, session: req.session}

app.get '/favicon.ico', (req,res)->
  res.sendfile "#{__dirname}/pub/img/favicon.ico"


app.get '/ck.js', (req,res)->
  res.sendfile "#{__dirname}/node_modules/coffeekup/lib/coffeekup.js"


app.get '/github/callback', (req,res)->
  console.log req.query
  res.redirect '/'

app.get '/twitter/callback', (req,res)->
  console.log req.query
  res.redirect '/'


app.get /^\/js\/([^e]+)(\/(.+)\.js)?/, (req,res)->
  console.log req.params

  bd = new Bundler()
  bd.getBundle req.params[0].split('/')

  bd.on 'bundle', (bundle)->
    res.send bundle, { 'Content-type':'text/javascript' }

app.get '/s', (req,res)->
  store.get req.session.id, (e,s)->
    res.json {id: req.session.id, ck: req.cookies, e, s: s}


###
io.set 'authorization', (data, accept)->
    # check if there's a cookie header
    if (data.headers.cookie)
        # if there is, parse the cookie
        data.cookie = parseCookie(data.headers.cookie)
        # note that you will need to use the same key to grad the
        # session id, as you specified in the Express setup.
        data.sessionID = data.cookie['express.sid']
    else
       # if there isn't, turn down the connection with a message
       # and leave the function.
       return accept('No cookie transmitted.', false)
    # accept the incoming connection
    accept(null, true)
###

sio.sockets.on 'connection', (socket)->
  console.log 'session: ', socket.handshake
  cookieStr = _.find socket.handshake.headers.cookie.split(';'), (i)-> /express\.sid/.test(i)
  ssid = unescape cookieStr?.split('=')[1]
  console.log 'ssid: ',ssid

  # receive data from backbone sync
  socket.on 'script', (data,cb)->
    console.log 'read: ',JSON.stringify data
    switch data.method
      when 'codeExists'
        if (code = data.code)
          Script.findOne { code: code }, (err,script)=>
            console.log 'hi: ',script
            cb(script)
      when 'read'
        if (code = data.options.code)
          Script.findOne {code: code}, (err,script)=>
            @emit 'script', 'read', script
        else if (list = data.options.list)
          Script.list list, (err,matchingScripts)=>
            console.log 'sending ',_.pluck matchingScripts, 'code'
            @emit 'script', 'read', matchingScripts
        else if (q = data.options.query)
          Script.search q, (err, matchingScripts)=>
            console.log 'sending ',_.pluck matchingScripts, 'code'
            @emit 'script', 'read', matchingScripts
        else
          Script.find (err,scripts)=>
            @emit 'script', 'read', scripts

  # request for a script bundle
  socket.on 'scrundle', (codes)->
    console.log 'recv:',codes
    bd = new Bundler()

    bd.getBundle codes

    bd.on 'bundle', (bundle)=>
      @emit 'scrundle:source', bundle

    bd.on 'progress', (count)=>
      @emit 'scrundle:progress', count


app.listen 8080
