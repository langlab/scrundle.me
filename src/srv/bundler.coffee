url = require 'url'
http = require 'http'
https = require 'https'
events = require 'events'
_ = require 'underscore'
db = require './db'
Script = db.Script

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
    #console.log 'BUNDLING: ',scriptKeys
    bundle = []
    scriptsDownloaded = 0
    
    
    Script.where('code').in(scriptKeys).exec (err,scripts)=>  
      if err then console.log err
      
      scripts = _.sortBy scripts, (s)-> _.indexOf scriptKeys, s.code
      scriptTitles = _.map scripts, (scr)-> "#{ scr.title ? '' } (#{ scr.code ? '' })"

      for script, i in scripts
        @getScript script.versions.latest, i, (ord,scriptData)=>
          bundle[ord] = scriptData
          scriptsDownloaded++
          @emit 'progress', scriptsDownloaded
          if scriptsDownloaded is scripts.length
            bundled = '/* scripts bundled with ♥ by scrundle.me -- includes :'+scriptTitles.join(', ')+'*/ \n'
            @emit 'bundle', bundled + bundle.join ';'

module.exports = Bundler