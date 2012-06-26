
express = require 'express'
store = new express.session.MemoryStore()
ck = require 'coffeekup'
_ = require 'underscore'
db = require './db'
mongoose = db.mongoose
Bundler = require './bundler'
baseDir = __dirname.replace '/src/srv',''

mongooseAuth = require 'mongoose-auth'

app = express.createServer()

app.configure ->
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session {
    secret: 'keyboardCat'
    key: 'express.sid'
    store: store
  }
  app.use express.bodyParser()
  app.use mongooseAuth.middleware()
  app.use express.static "#{baseDir}/pub"
  app.set 'views', "#{baseDir}/src/views"
  app.set 'view options', { layout: false }
  app.set 'view engine', 'coffee'
  app.register '.coffee', require('coffeekup').adapters.express
  app.use express.errorHandler()

mongooseAuth.helpExpress(app)

app.store = store

app.get '/', (req,res)->
  console.log 'req.session: ',req.session.id
  req.session.user = req.user
  res.render 'index', {user: req.user, session: req.session}

app.get '/favicon.ico', (req,res)->
  res.sendfile "#{baseDir}/pub/img/favicon.ico"


app.get '/ck.js', (req,res)->
  res.sendfile "#{baseDir}/node_modules/coffeekup/lib/coffeekup.js"


app.get '/github/callback', (req,res)->
  res.redirect '/'

app.get '/twitter/callback', (req,res)->
  res.redirect '/'


app.get /^\/js\/([^e]+)(\/(.+)\.js)?/, (req,res)->

  bd = new Bundler()
  bd.getBundle req.params[0].split('/')

  bd.on 'bundle', (bundle)->
    res.send bundle, { 'Content-type':'text/javascript' }

app.get '/s', (req,res)->
  store.get req.session.id, (e,s)->
    res.json {id: req.session.id, ck: req.cookies, e, s: s}

app.listen 4401

module.exports = app

  