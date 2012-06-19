w = window
w.sock = w.io.connect 'http://localhost:4444'

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

Backbone.Model::connectSocket = Backbone.View::connectSocket = ->
  @io ?= window.sock

Backbone.sync = (method,model,options)->
  @io ?= window.sock
  @io.emit 'script', {method: method, id: model.id?, options: options}

  io = @io
  @io.on 'script', (method,data)->
    console.log 'recvd: ',data
    delete @$events.script
    options.success data

class Script extends Backbone.Model
  initialize: ->
    @id = @attributes.code

  defaults:
    selected: false

  isSelected: -> @get 'selected'

  select: ->
    @set 'selected', true

  unSelect: ->
    @set 'selected', false

class Scripts extends Backbone.Collection
  model: Script

  comparator: (s)->
    s.get('uses')

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
    "http://scrundle.me/#{ @selectedCodes.join('/') }"

  getPath: ->
    @selectedCodes.join '/'

  parse: (resp)->
    console.log 'fetched: ',resp
    filtered = _.filter resp, (s)=> 
      alreadyExists = (not (@where {code: s.code}).length)
      #console.log s, alreadyExists
      alreadyExists

    console.log 'filtered', filtered
    filtered


  selectedCount: ->
    (@filter (s)-> s.get 'selected').length

  nonSelectedCount: ->
    @length - @selectedCount()


# VIEWS

Backbone.View::open = (cont = '.main')->
  @$el.appendTo cont
  @

class NavBar extends Backbone.View
  tagName: 'div'
  className: 'navbar navbar-fixed-top'

  template: ->
    div class:'navbar-inner', ->
      div class:'container', ->
        a class:'brand', 'scrundle.me'
        ul class:'nav', ->
          li ->
            a href:'#', 'About'
          li ->
            a href:'#finder-view', 'Bundle Scripts'
          li ->
            a href:'#add-scripts', 'Add New Scripts'



  render: ->
    @$el.html ck.render @template
    @


class ScriptView extends Backbone.View
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
      span class:'label', "#{@model.get('code')}"
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
    @



class Finder extends Backbone.View
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
    @$('.icon-search').hide()
    @$('img.wait').show()
    clearInterval @searchTimer
    query = $(e.target).val()
    console.log 'doing query: ',query
    @collection.clearNonSelected()
    @collection.fetch { 
      add: true
      query: query
      success: =>
        @renderScripts()
        @$('.icon-search').show()
        @$('img.wait').hide()
    }
    if $(e.target).val() then @$('.add-btn').show()
    else @$('.add-btn').hide()

  template: ->
    div class:'row', ->
      div class:'span6 pull-left', ->
        div 'page-header', ->
          h2 ->
            span class:'badge badge-info', '1'
            text ' Find and select scripts.'
        div class:'control-group', ->
          div class:'controls search-control', ->
            div class:'input-prepend', ->
              span class:'add-on', ->
                i class:'icon-search'
                img class:'wait', src:'/img/wait.gif'
              input class:'span3 search', type:'text', placeholder:'find scripts to bundle', tabindex:1
              a class:'btn add-btn btn-info', tabindex:2, ->
                text 'add all these  '
                i class:'icon-white icon-chevron-right'
        div class:'script-list-cont', ->
          table class:'table', ->
            tbody ->

      div class:'span6 pull-right', ->
        div class:'page-header', ->
          h2 ->
            span class:'badge badge-info', '2'
            text ' Put them in order.'

        div class:'selected-cont', ->
          div class:'selected-list-cont', ->  
            table class:'table', ->
              tbody ->

  unSelect: (s)->
    s.view.remove().render().$el.prependTo @$('.script-list-cont tbody')
    s.view.delegateEvents()
    @setSelectedCodes()
    @

  select: (s)->
    s.view.remove().render().$el.appendTo @$('.selected-list-cont tbody')
    s.view.delegateEvents()
    @setSelectedCodes()
    @

  addScript: (s)->
    s.view ?= new ScriptView { model: s }
    s.view.remove().render().$el.appendTo @$('.script-list-cont tbody')
    s.view.delegateEvents()

  renderScripts: ->
    for s in @collection.getUnSelected()
      @addScript s
    @

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
      update: =>
        @setSelectedCodes()
    }).disableSelection()

    @

  setSelectedCodes: ->
    @collection.selectedCodes = _.map $('.selected-list-cont .code .label'), (el)-> $(el).text()
    @collection.trigger 'change:selectedCodes'


    


class BundleView extends Backbone.View
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

  events:
    'click code, pre':'selectCode'
    'click .loadSrc':'loadSource'

  loadSource: ->
    @io.emit 'scrundle', @collection.getSelectedCodes()
    @$('.loadSrc').hide()
    @$('.progress').show().slideDown({direction: 'left'})


  selectCode: (e)->
    @$(e.target).selectText()

  template: ->
    div class:'page-header', ->
      h2 ->
        span class:'badge badge-info', '3'
        text ' Get your script bundle.'

    div class:'row command-view', ->
      div class:'span6', ->
        if (selected = @collection.getSelected()).length
          div class:'span9', ->
            h4 class:'', 'Download it from the command line:'
            code class:'code curl pull-left span9', "curl #{@collection.getUrl()} > bundle.js"
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
    @

class Router extends Backbone.Router

  initialize: ->
    @scripts = new Scripts()
  
  routes:
    '':'home'

  home: ->
    navBar = (new NavBar()).render().open('body')
    
    @finder = new Finder { collection: @scripts }
    @finder.render().open('.main')

    @bundleView = new BundleView { collection: @scripts }
    @bundleView.render().open '.main'

    @scripts.fetch {
      add: true
      success: =>
        @finder.renderScripts()
    }

    @scripts.on 'change:selectedCodes', =>
      @bundleView.render()


w.app = new Router()
w.ck = CoffeeKup


$ ->
  Backbone.history.start()
  console?.log 'jquery loaded'

