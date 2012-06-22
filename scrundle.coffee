
express = require 'express'
store = new express.session.MemoryStore()
ck = require 'coffeekup'
_ = require 'underscore'
db = require './src/srv/db'
User = db.User
Script = db.Script
mongoose = db.mongoose
Bundler = require './src/srv/bundler'

mongooseAuth = require 'mongoose-auth'

app = express.createServer()
io = require('socket.io').listen app

app.configure ->
  app.use express.methodOverride()
  app.use express.static "#{__dirname}/pub"
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session {secret: 'keyboardCat', key: 'express.sid', store: store}
  app.use mongooseAuth.middleware()
  app.set 'views', "#{__dirname}/src/views"
  app.set 'view options', { layout: false }
  app.set 'view engine', 'coffee'
  app.register '.coffee', require('coffeekup').adapters.express
  app.use express.errorHandler()


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

io.sockets.on 'connection', (socket)->

  # receive data from backbone sync
  socket.on 'script', (data)->
    console.log 'read: ',JSON.stringify data
    switch data.method
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

mongooseAuth.helpExpress(app)
app.listen 4444
