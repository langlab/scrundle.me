# models and views
# only used by an authorized user

module 'Scrundle.User', (exports, top)->

  class Model extends Backbone.Model

    getName: ->
      @get('twit').name

    getIconUrl: ->
      @get('twit').profileImageUrl

  exports.Model = Model



Scrundle.Script.Model::isCodeValid = (code,cb)->
  @io.emit 'script', {method: 'codeExists', code: code}, (script)=>
    @codeValid = (not script?) or (script._id is @id)
    cb(@codeValid)
    


# add an edit view to the Scrupt module
# for logged-in users only

class Scrundle.Script.Views.Edit extends Backbone.View
  
  tagName:'div'
  className:'edit-view modal hide'

  urlTemplate: ->
    fieldset class:'control-group', ->
      input type:'text', class:'span2', placeholder:'script url'

  events:
    'keyup input.title, input.code': ->
      @updateTitle()
      @checkCode()


  checkCode: ->

    codeError= (errText)->
      if errText then @$('.control-group.code').addClass('error') else @$('.control-group.code').removeClass('error')
      @$('.code .help-block').text errText

      # checkCode returns the error or empty/falsy string
      errText


    if @$('input.code').val() is ''
      codeError 'You must enter a code.'
    else
      @model.isCodeValid @$('input.code').val(), (codeAvailable)=>
        console.log codeAvailable
        alreadyExists = not codeAvailable
        if alreadyExists
          codeError 'This code already exists. Try another' 
        else
          codeError ''
      
        
  updateTitle: (e)->
    @$('.title-label').text( @$('input.title').val() ? 'New script' )
    @$('.code-label').text( if (code = @$('input.code').val()) then " (#{ code })" else '' )
    

    

  template: ->
    div class:'modal-header', ->
      h3 ->
        span class:'title-label', "#{ @get('title') ? 'New script' }"
        if (code = @get('code'))?
          span class:'code-label', " (#{ code })"
    div class:'modal-body', ->
      form class:'edit-form form-inline', ->
        fieldset class:'control-group code', ->
          div class:'controls', ->
            input type:'text',class:'code span1',placeholder:'code',value:"#{ @get('code') ? '' }"
            p class:'help-block'
        fieldset class:'control-group title', ->
          div class:'controls', ->
            input type:'text',class:'title span3',placeholder:'title',value:"#{ @get('title') ? ''}"
        fieldset class:'control-group', ->
          textarea class:'description', placeholder:'script description...', "#{ @get('description') ? '' }"

    div class:'modal-footer', ->
      button class:'btn btn-success save', 'save'

  render: ->
    @$el.html ck.render @template, @model
    @

  open: ->
    @$el.modal 'show'
    @delegateEvents()
    @


$ ->

  Scrundle.app.views.editView = new Scrundle.Script.Views.Edit()
  
  Scrundle.app.user = new Scrundle.User.Model window.user
  Scrundle.app.views.navBar.login(Scrundle.app.user)

  # route for editing a script
  Scrundle.app.route 'edit/:code','editOne', (code)->
    @closeViews()
    @views.editView.model = new Scrundle.Script.Model()
    if code
      @views.editView.model.fetch {
        code: code
        success: =>
          console.log @views.editView.model
          @views.editView.render().open('body')
        error: =>
          alert('no code by that name')
          @navigate '/',true
      }
    else
      @views.editView.render().open('body')
    
    @
