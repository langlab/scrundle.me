
# contains models and view for all users, 
# even signed out

w = window
w.sock = w.io.connect 'http://dev.scrundle.me'
w.ck = CoffeeKup

$.fn.selectText = ->
    text = $(this)[0]

    if ($.browser.msie)
      range = document.body.createTextRange()
      range.moveToElementText(text)
      range.select()
    else if ($.browser.mozilla or $.browser.opera)
      selection = window.getSelection()
      range = document.createRange()
      range.selectNodeContents(text)
      selection.removeAllRanges()
      selection.addRange(range)
    else if ($.browser.safari)
      selection = window.getSelection()
      selection.setBaseAndExtent(text, 0, text, 1)

# make setTimeout and setInterval less awkward
# by switching the parameters!!
w.wait = (someTime,thenDo) ->
  setTimeout thenDo, someTime
w.doEvery = (someTime,action)->
  setInterval action, someTime

# include the socket connection in every Model and View
Backbone.Model::connectSocket = Backbone.Collection::connectSocket = Backbone.View::connectSocket = ->
  @io ?= window.sock

Backbone.View::open = (cont = '.main')->
  @$el.appendTo cont
  @

# to create modules/namespaces
module = (target, name, block) ->
  [target, name, block] = [(if typeof exports isnt 'undefined' then exports else window), arguments...] if arguments.length < 3
  top    = target
  target = target[item] or= {} for item in name.split '.'
  block target, top


# the main app module

module 'Scrundle', (exports, top)->
  
  class Session extends Backbone.Model
    isLoggedIn: ->


  exports.Views = Views = {}

  class Views.NavBar extends Backbone.View
    el: $('.navbar')

    menuTemplate: ->
      li class:'divider-vertical'
      li class:'dropdown', ->
        a href:'dropdown-toggle', 'data-toggle':'dropdown', ->
          img src: "#{@getIconUrl()}"
          text " #{ @getName() } "
          b class:'caret'
        ul class:'dropdown-menu', ->
          li ->
            a href:'/logout', 'Sign out'

    login: (@model)->
      @$('.user-info').html ck.render @menuTemplate, @model

  class Views.About extends Backbone.View
    tagName:'section'
    class:'about-view'

    template: ->
      div class:'hero-unit title', ->
        img src:'/img/logo.svg'
        div class:'row', ->
          div class:'span9', ->
            h1 "Scrundle"
            p "Use my name like a verb and I'll order and bundle scripts in a nice package for you."
            p "For example, to get jQuery + underscoreJS + backboneJS in order and save locally, just curl an instructional url, like this:"
            div class:'code',->
              span class:'code terminal', ->
                i class:'icon-chevron-right terminal-prompt'
                text "&nbsp;"
                span "curl http://scrundle.me/js/$/_/bb > bundle.js"
            p "I'll even provide you with a single page with docs for your scripts, available here:"
            div class:'code',->
              span class:'link', ->
                i class:'icon-book icon-large'
                text " "
                a href:'/#docs/$/_/bb', target:'_blank', "http://scrundle.me/#docs/$/_/bb "
            p "As you can see, you need to know the special codes for the scripts you want! So, I made a nice tool for you to find and select your scripts."
            a class:'btn btn-info', href:'#finder-view', 'Get Started!'
            div class:'container', ->
              div ->
                p ->
                  text "Why am I doing this, "
                  a href:'#why', 'you may ask?'

    pullUp: (cb)->
      @$el.slideUp =>
        @remove()
        cb()

    pullDown: (cb)->
      @$el.appendTo('.main').slideDown cb

    render: ->
      @$el.html ck.render @template
      @

  class Views.Why extends Backbone.View
    tagName: 'div'
    className: 'modal hide'

    template: ->
      div class:'modal-header', ->
        h2 'Why do I scrundle?'
      div class:'modal-body', ->
        p 'My creator got tired of hunting around, copying and pasting urls for every script he needed to quickly get familiar with a library or prototype an idea. So he made me to automate this tedious work for him. The process of learning and experimentation is easier.'
        h4 'Would you like to help?'
        p 'There are two ways you can:'
        ol ->
          li 'add new javascript urls to the library'
          li ->
            text 'make a quick donation to my creator'
            form action:"https://checkout.google.com/api/checkout/v2/checkoutForm/Merchant/302846056348109", id:"BB_BuyButtonForm", method:"post", name:"BB_BuyButtonForm",target:"_blank", ->
              input name:"item_name_1",type:"hidden",value:"scrundle donation"
              input name:"item_description_1",type:"hidden",value:""
              input name:"item_quantity_1",type:"hidden",value:"1"
              input name:"item_price_1",type:"hidden",value:"2.0"
              input name:"item_currency_1",type:"hidden",value:"USD"
              input name:"shopping-cart.items.item-1.digital-content.url",type:"hidden",value:"http://scrundle.me"
              input name:"_charset_",type:"hidden",value:"utf-8"
              input alt:"",src:"https://checkout.google.com/buttons/buy.gif?merchant_id=302846056348109&amp;w=121&amp;h=44&amp;style=white&amp;variant=text&amp;loc=en_US",type:"image"

      div class:'modal-footer', ->
        button class:'btn btn-success', 'close'

    render: ->
      @$el.html ck.render @template
      @

    open: ->
      @$el.modal('show')

  class exports.Router extends Backbone.Router

    initialize: ->

      @scripts = new Scrundle.Script.Collection()
      @docs = new Scrundle.Script.Collection()
      @views = 
        navBar: new Scrundle.Views.NavBar()
        about: new Scrundle.Views.About()
        finder: new Scrundle.Script.Views.Finder { collection: @scripts }
        bundleView: new Scrundle.Script.Views.Bundle { collection: @scripts }
        whyView: new Scrundle.Views.Why()
        docsView: new Scrundle.Script.Views.Docs { collection: @docs }
        

    closeViews: ->
      for name,v of @views
        if name isnt 'navBar' then v.remove()
    
    routes:
      '':'home'
      'finder-view':'finder'
      'why':'why'
      'docs/*list':'docs'

    home: ->
      @closeViews()
      @scripts.reset()
      @views.navBar.open('.main')
      @views.about.render().pullDown()
      
    finder: ->
      @views.about.pullUp =>
        @views.finder.render().open('.main')
        @views.bundleView.render().open $('.main')

        @scripts.fetch {
          add: true
          success: =>
            @views.finder.renderScripts()
            @views.finder.$('.search').focus()
        }

    why: ->
      @views.whyView.remove().render().open()

    docs: (list)->
      @closeViews()
      @views.navBar.remove()
      @docs.fetch {
        list: list.split('/')
        success: =>
          @views.docsView.render().open('body')
      }


# module for Scripts      

module 'Scrundle.Script', (exports, top)->

  # socket.io sync replacement for Scripts
  exports.scriptReadSync = scriptReadSync = (method,model,options)->
    @io ?= window.sock
    console.log 'sync: ',method,model,options
    if method is 'read'
      @io.emit 'script', {method: method, id: model.id, options: options}

      io = @io
      @io.on 'script', (method,data)->
        delete @$events.script
        options.success data



  class Model extends Backbone.Model

    idAttribute: "_id"

    defaults:
      selected: false
      uses: 0

    scriptReadSync: scriptReadSync
    sync: scriptReadSync

    isSelected: -> @get 'selected'

    select: ->
      @set 'selected', true

    unSelect: ->
      @set 'selected', false

    isCodeValid = (code,cb)->
      @io.emit 'script', {method: 'codeExists', code: code}, (script)=>
      @codeValid = (not script?) or (script._id is @id)
      cb(@codeValid)

  class Collection extends Backbone.Collection
    model: Model

    sync: scriptReadSync

    comparator: (s)->
      if (selOrder = s.get('selected')) > 0
        selOrder
      else
        0 - parseInt s.get('uses'), 10

    clearNonSelected: ->
      @remove @getUnSelected()

    selectAll: ->
      @invoke 'select'

    getUnSelected: ->
      @filter (s)-> not s.get 'selected'

    getSelected: ->
      @filter (s)-> s.get 'selected'

    getSelectedCodes: ->
      _.map @getSelected(), (s)-> s.get('code')

    getUrl: ->
      "http://scrundle.me/js/#{ @getSelectedCodes().join('/') }"

    getPath: ->
      "/js/#{ @getSelectedCodes().join '/' }"

    parse: (resp)->
      filtered = _.filter resp, (s)=> 
        alreadyExists = (not (@where {code: s.code}).length)
      filtered


    selectedCount: ->
      (@filter (s)-> s.get 'selected').length

    nonSelectedCount: ->
      @length - @selectedCount()

  
  exports.Model = Model
  exports.Collection = Collection

  exports.Views = Views = {}

  class Views.ListItem extends Backbone.View
    tagName: 'tr'
    className: 'script-view'

    initialize: ->

    events:
      'click .select-btn':'toggleSelect'

    template: ->
      if @model.get 'selected'
        td class:'select-btn', -> 
          span class:'icn left', -> i class:'icon-chevron-left'
      td class:'code', ->
        span class:"label#{ if @model.isSelected() then ' label-info' else ''}", "#{@model.get('code')}"
      td "#{@model.get('title')}"
      td "#{@model.get('description')}"
      if not @model.get 'selected'
        td class:'select-btn', -> 
          span class:'icn right', -> i class:'icon-chevron-right'

    toggleSelect: ->
      @model.set 'selected', (not @model.get 'selected')
      console.log 'clicked: ',@model

    render: ->
      @$el.html ck.render @template, @
      @$el.attr 'id', @model.id
      @


  class Views.Finder extends Backbone.View
    tagName: 'section'
    id: 'finder-view'

    initialize: ->

      @collection.on 'change', (s)=>
        if s.isSelected() then @select(s)
        else @unSelect(s)

      @collection.on 'remove', (s)=>
        s.view.remove()

    events:
      'keyup .search': 'setSearchTimer'
      'blur .search': ->
        @$('.add-btn')[0].focus()
      'keydown .add-btn': 'selectAll'
      'click .add-btn': 'selectAll'

    template: ->
      div class:'row', ->
        div class:'span6 pull-left search-cont', ->
          div 'page-header', ->
            h2 ->
              span class:'icon-search icon-large steps'
              text ' Find and select scripts.'
          div class:'control-group', ->
            div class:'controls search-control', ->
              div class:'input-prepend', ->
                span class:'add-on', ->
                  i class:'icon-search'
                  img class:'wait', src:'/img/wait.gif'
                input class:'span3 search', type:'text', placeholder:'find scripts to bundle', tabindex:1
                a class:'btn add-btn btn-info', tabindex:2, ->
                  text '&darr; add all these  '
                  i class:'icon-white icon-chevron-right'
          div class:'script-list-cont', ->
            table class:'table', ->
              tbody ->

        div class:'span6 pull-right selected-cont', ->
          div class:'page-header', ->
            h2 ->
              span class:'icon-reorder icon-large steps'
              text ' Put them in order.'

          div class:'selected-list-cont', ->  
            table class:'table', ->
              thead ->
                tr -> th colspan:4, class:'count', "&larr; Find some scripts!"
              tbody ->

    selectAll: (e)->
      if e.which in [13,1]
        @collection.selectAll()
        @$('.search').select().val('').keyup()
        @$('.add-btn').hide()
        @

    setSearchTimer: (e)->
      clearInterval @searchTimer
      switch e.which
        when 13 then @doSearch(e)
        when 27
          $(e.target).val ''
          $(e.target).focus()
          @doSearch(e)
        else
          @searchTimer = wait 300, =>
            @doSearch(e)

    doSearch: (e)->
      @$('.input-prepend .icon-search').hide()
      $('img.wait').show()
      clearInterval @searchTimer
      query = $(e.target).val()
      console.log 'doing query: ',query
      @collection.clearNonSelected()
      @collection.fetch { 
        add: true
        query: query
        success: =>
          console.log 'fetch success'
          @renderScripts()
          @$('.input-prepend .icon-search').show()
          @$('img.wait').hide()
      }
      if $(e.target).val() then @$('.add-btn').show()
      else @$('.add-btn').hide()

   

    updateSelected: ->
      cnt = @collection.selectedCount()
      if cnt
        @$('.selected-cont').fadeIn()
        @$('.count').html ck.render ->
          text 'You have '
          span class:'label label-info', "#{@}"
          text " bundled script#{if @ > 1 then 's' else ''}. Drag to order."
        ,cnt
      else
        @$('.selected-cont').fadeOut()
      @setScriptOrder()


    unSelect: (s)->
      s.view.remove().render().$el.prependTo @$('.script-list-cont tbody')
      s.view.delegateEvents()
      @updateSelected()
      @

    select: (s)->
      s.view.remove().render().$el.appendTo @$('.selected-list-cont tbody')
      s.view.delegateEvents()
      @updateSelected()
      @

    addScript: (s)->
      s.view ?= new Views.ListItem { model: s }
      s.view.remove().render().$el.appendTo @$('.script-list-cont tbody')
      s.view.delegateEvents()

    renderScripts: ->
      for s in @collection.getUnSelected()
        @addScript s
      @

    setScriptOrder: ->
      idsInOrder = _.compact _.map @$('.selected-list-cont tr'), (i)-> $(i).attr('id')
      for id,i in idsInOrder
        @collection.get(id).set('selected',i+1, {silent:true})
        @collection.sort {silent: true}
      @collection.trigger 'change:selectedCodes'

    render: ->
      @$el.html ck.render @template
      fixHelper = (e, ui)->
        ui.children().each ->
          $(this).width $(this).width()
        return ui

      @$('.selected-list-cont tbody').sortable({ 
        items: 'tr' 
        helper: fixHelper
        cursor: 'move'
        update: (ev,ui)=>
          @setScriptOrder()
          
      }).disableSelection()
      @delegateEvents()
      @

  class Views.Bundle extends Backbone.View
    tagName: 'section'
    id: 'bundle-view'

    initialize: ->
      @connectSocket()

      @io.on 'scrundle:source', (src)=>
        @$('.progress').hide()
        @$('.src').text(src)
        @$('.src-view').slideDown()

      @io.on 'scrundle:progress', (count)=>
        scriptCount = @collection.getSelectedCodes().length
        console.log 'prog: ', prog = Math.floor (100*count/scriptCount)
        @$('.progress .bar').css('width',"#{prog}%")

      @collection.on 'change:selectedCodes', =>
        @render()

    events:
      'click code, pre':'selectCode'
      'click .loadSrc':'loadSource'

    loadSource: ->
      console.log @collection.getSelectedCodes()
      @io.emit 'scrundle', @collection.getSelectedCodes()
      @$('.loadSrc').hide()
      @$('.progress').show().slideDown({direction: 'left'})


    selectCode: (e)->
      @$(e.target).selectText()

    template: ->
      div class:'page-header', ->
        h2 ->
          span class:'icon-briefcase icon-large steps'
          text ' Get your script bundle.'

      div class:'row command-view', ->
        if (selected = @collection.getSelected()).length
          div class:'span9', ->
            h4 class:'', 'Download it from the command line:'
            pre class:'code terminal', ->
              i class:'icon-chevron-right'
              text "&nbsp;"
              span class:'curl', "curl #{@collection.getUrl()} > bundle.js"
            div
            button class:'btn btn-info loadSrc', 'or scrundle it here &darr;'
            div class:'progress progress-striped active span9', ->
              div class:'bar',style:'width: 0%'
            
      div class:'row src-view', ->
        div class:'span9 pull-left', ->
          pre class:'pre-scrollable src'
        div class:'logo span3 pull-right', ->
          img src:'/img/logo.svg'
        
    render: ->
      @$el.html ck.render @template, @
      if @collection.selectedCount() then @$el.fadeIn()
      else @$el.fadeOut()
      @delegateEvents()
      @

  class Views.Docs extends Backbone.View
    tagName:'div'
    className:'docs'

    events:
      'click .doc.btn': (e)-> 
        console.log 'click',e
        @$('.doc').removeClass('btn-info')
        $(e.target).addClass('btn-info')
        @loadUrl $(e.target).attr('data-code'), $(e.target).attr('data-url')

    loadUrl: (@code, @url)->
      console.log @url
      @$('iframe').attr 'src', @url


    template: ->
      
      div class:'tabbable tabs-left left-bar ', ->
        ul class:'nav nav-tabs', ->
          li ->
            a class:'', href:'/', ->
              img src:'/img/logo.svg'
          @each (scr,i)->
            li ->
              a class:'doc',href:"##{ scr.id }", 'data-toggle':'tab', "#{ scr.get('code') }"
          
        div class:'tab-content', ->
          @each (scr,i)->
            div class:"tab-pane#{ if i is 0 then ' active' else ''}",id:"#{ scr.id }", ->
              iframe class:'with-left-bar', src:"#{ scr.get('docs') }",frameborder:'0'


    template2: ->
      iframe class:'with-float-bar',src:"#{ @url ?= @first().get('docs') }",frameborder:'0', ->
      div class:'btn-group docs-bar', ->
        span class:'btn handle',->
          i class:'icon-move'
        a class:'btn doc', href:'/', ->
          img src:'/img/logo.svg'
        @each (scr,i)->
          button class:"btn doc#{ if i is 0 then ' btn-info' else '' }", 'data-code':"#{ scr.get('code')} ", 'data-url':"#{ scr.get('docs') }", "#{ scr.get('code') } "

    render: ->
      @$el.html ck.render @template, @collection
      @$('a.doc').click (e)->
        console.log 'click', $(e.target)
        e.preventDefault()
        $(e.target).tab('show')

      @$('a.doc:first').tab('show')

      ###
      @$('.docs-bar').draggable({
        handle: '.handle'
        iframeFix: true
      }).css({ position: 'absolute', bottom: '10px', right: '10px' })
      ###
      @delegateEvents() 
      @

  
$ ->
  Scrundle.app ?= new Scrundle.Router()
  Backbone.history.start()

