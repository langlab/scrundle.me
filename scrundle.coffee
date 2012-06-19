
express = require 'express'
ck = require 'coffeekup'
scriptsJSON = require './scripts'
_ = require 'underscore'

url = require 'url'
http = require 'http'
https = require 'https'
events = require 'events'

mongoose = require 'mongoose'
mongoose.connect 'mongodb://localhost/scrundle'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId


ScriptSchema = new Schema {
  code: String
  title: String
  description: String
  versions: {}
}

ScriptSchema.statics =
  search: (term,cb)->
    @find({
      $or: [ 
        { title: { $regex: term, $options: 'i' } }
        { description: { $regex: term, $options: 'i' } }
        { code: { $regex: term, $options: 'i' } } 
      ]
    }).exec (err,scripts)=>
      cb err, scripts


Script = mongoose.model 'script', ScriptSchema
###
# insert into db
for s in scriptsJSON
  scr = new Script s
  scr.save()
###

app = express.createServer()
io = require('socket.io').listen app

app.configure ->
  app.use express.static "#{__dirname}/pub"
  app.use express.bodyParser()
  app.set 'views', "#{__dirname}/src/views"
  app.set 'view options', { layout: false }
  app.set 'view engine', 'coffee'
  app.register '.coffee', require('coffeekup').adapters.express


class Bundler extends events.EventEmitter

  getScript: (uri,ord,cb)->
    rObj = url.parse uri
    scriptData = ''
    httpLib = if rObj.protocol is 'https:' then https else http
    httpLib.get { host: rObj.host, path: rObj.path, port: rObj.port }, (resp)->
      resp.on 'data', (chunk)->
        scriptData = scriptData + chunk
      resp.on 'end', ->
        cb ord,scriptData

  getBundle: (scriptKeys)->
    
    bundle = []
    scriptsDownloaded = 0
    
    
    Script.where('code').in(scriptKeys).exec (err,scripts)=>  
      if err then console.log err
      #console.log scripts
      scriptTitles = _.map scripts, (scr)-> "#{ scr.title ? '' } (#{ scr.code ? '' })"

      for script,i in scripts
        @getScript script.versions.latest, i, (ord,scriptData)=>
          bundle[ord] = scriptData
          scriptsDownloaded++
          @emit 'progress', scriptsDownloaded
          if scriptsDownloaded is scripts.length
            bundled = '/* scripts bundled with love by scrundle.me -- includes :'+scriptTitles.join(', ')+'*/ \n'
            @emit 'bundle', bundled + bundle.join ';'


app.get '/', (req,res)->
  res.render 'index'

app.get '/ck.js', (req,res)->
  res.sendfile "#{__dirname}/node_modules/coffeekup/lib/coffeekup.js"


app.get /^\/([^e]+)(\/(.+)\.js)?/, (req,res)->
  console.log req.params

  bd = new Bundler()
  bd.getBundle req.params[0].split('/')

  bd.on 'bundle', (bundle)->
    res.send bundle, { 'Content-type':'text/javascript' }

io.sockets.on 'connection', (socket)->
  # receive data from backbone sync
  socket.on 'script', (data)->
    console.log 'read: ',data
    switch data.method
      when 'read'
        if (q = data.options.query)
          Script.search q, (err, matchingScripts)=>
            @emit 'script', 'read', matchingScripts
        else
          Script.find (err,scripts)=>
            @emit 'script', 'read', scripts

  socket.on 'scrundle', (codes)->
    console.log 'recv:',codes
    bd = new Bundler()

    bd.getBundle codes

    bd.on 'bundle', (bundle)=>
      @emit 'scrundle:source', bundle

    bd.on 'progress', (count)=>
      @emit 'scrundle:progress', count


app.listen 4444
