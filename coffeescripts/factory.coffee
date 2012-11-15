# Factory - Interactions
# ======================

DEFAULT_SLIDE = """
  # Introducing Factory

  Factory is an in-browser slide creation and
  publishing too.
"""

# The slide text editor
class Editor extends Backbone.View
  initialize: ->
    @loadFixture()

  loadFixture: ->
    @$el.val DEFAULT_SLIDE


# The right-hand part where the current slide gets shown.
class SlideViewer extends Backbone.View
  initialize: ->
    @newSlide()

  newSlide: ->
    @$el.empty()
    $slide = $ @make 'div', class: 'slide'
    @$el.append $slide


$ ->
  # Keep a global reference around
  window.Factory = {}

  Factory.Editor      = new Editor el: $('.writing textarea')
  Factory.SlideViewer = new SlideViewer el: $('.slide-container')
