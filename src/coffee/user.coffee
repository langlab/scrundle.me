# models and views
# only used by an authorized user


class User extends Backbone.Model

  getName: ->
    @get('twit').name

  getIconUrl: ->
    @get('twit').profileImageUrl


class EditView extends Backbone.View
  
  tagName:'div'
  className:'edit-view modal hide'

  urlTemplate: ->
    fieldset class:'control-group', ->
      input type:'text', class:'span2', placeholder

  events:
    'keyup input.title, input.code': 'updateTitle'


  updateTitle: (e)->
    @$('.title-label').text( @$('.title').val() ? 'New script' )
    @$('.code-label').text( if (code = @$('.code').val()) then " (#{ code })" else '' )

  template: ->
    div class:'modal-header', ->
      h3 ->
        span class:'title-label', "#{ @get('title') ? 'New script' }"
        if (code = @get('code'))?
          span class:'code-label', " (#{ code })"
    div class:'modal-body', ->
      form class:'edit-form form-inline', ->
        fieldset class:'control-group', ->
          div class:'controls', ->
            input type:'text',class:'code span1',placeholder:'code',value:"#{ @get('code') ? '' }"
            input type:'text',class:'title span3',placeholder:'title',value:"#{ @get('title') ? ''}"
            p class:'help-block'
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

  app.views.editView = new EditView()
  
  app.user = new User window.user
  app.views.navBar.login(app.user)

  app.route 'edit/:code','editOne', (code)->
    @closeViews()
    @views.editView.model = new Script()
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
