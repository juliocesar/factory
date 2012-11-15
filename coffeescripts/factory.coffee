# Factory - Interactions
# ======================

# Keep a global reference around
window.Factory = {}

# Make it the app events hub
_.extend Factory, Backbone.Events

DEFAULT_SLIDE = """
  # Introducing Factory

  Factory is an in-browser slide creation and
  publishing tool.
"""

# The slide text editor
class Editor extends Backbone.View
  initialize: ->
    @loadFixture()
    @trackTextAreaChanges()

  loadFixture: ->
    @$el.val DEFAULT_SLIDE

  trackTextAreaChanges: ->
    @$el.on 'keyup change cut paste', =>
      Factory.trigger 'editor:updated', @$el.val()


# The right-hand part where the current slide gets shown.
class SlideViewer extends Backbone.View
  initialize: ->
    @newSlide()
    Factory.on 'editor:updated', (markdown) =>
      @updateSlide markdown

  newSlide: ->
    @$el.empty()
    @_currentSlide = $slide = $ @make 'div', class: 'slide'
    @$el.append $slide

  currentSlide: ->
    @_currentSlide ?= @$el.find '.slide'

  updateSlide: (markdown) ->
    @currentSlide().html marked(markdown)


# Boot it up
$ ->
  Factory.Editor      = new Editor el: $('.writing textarea')
  Factory.SlideViewer = new SlideViewer el: $('.slide-container')

  Factory.trigger 'editor:updated', $('.writing textarea').val()
