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

  No server setup required. Slides are served straight from
  your browser.
"""

# The slide text editor
class Editor extends Backbone.View
  initialize: ->
    @loadFixture()
    @trackTextAreaChanges()

  # Loads the fixture from DEFAULT_SLIDE into the editor
  loadFixture: ->
    @$el.val DEFAULT_SLIDE

  # Tracks changes made in the editor and fires editor:updated
  trackTextAreaChanges: ->
    @$el.on 'keyup change cut paste', =>
      Factory.trigger 'editor:updated', @$el.val()

# ---

# The right-hand part where the current slide gets shown.
class SlideViewer extends Backbone.View
  initialize: ->
    @newSlide()
    Factory.on 'editor:updated', (markdown) =>
      @updateSlide markdown

  # Creates a new slide
  newSlide: ->
    @$el.empty()
    @_currentSlide = $slide = $ @make 'div', class: 'slide'
    @$el.append $slide
    Factory.trigger 'newslide', $slide

  # Memoizes and returns the current slide's element
  currentSlide: ->
    @_currentSlide ?= @$el.find '.slide'

  # Compiles markdown from the text editor using marked()
  # and prints the markup to the current slide
  updateSlide: (markdown) ->
    @currentSlide().html marked markdown

# ---

# The slides browser
class SlidesBrowser extends Backbone.View
  # Slide entry template
  template: _.template """
    <li class="icon-star">
      <%= summary %>
      <button class="delete icon-trash"></button>
    </li>
  """

  initialize: ->
    Factory.on 'newslide', ($slide) => @addSlide $slide
    Factory.on 'toggleslides', (showOrHide) =>
      @toggleVisible showOrHide

  # Adds a slide to the list of slides
  addSlide: ($slide) ->
    $li = $ @template summary: @makeSummary($slide)
    @$el.append $li

  toggleVisible: (showOrHide) ->
    if showOrHide is 'show'
      @$el.fadeIn 250
    else
      @$el.fadeOut 100

  # Grabs some text from a slide so @addSlide can show
  # a preview
  makeSummary: ($slide) ->
    $slide.find('*:first-child').text()

# ---

# The app's main menu
class MainMenu extends Backbone.View
  events:
    'click .show-slides' : 'toggleSlides'

  toggleSlides: ->
    $button = $ event.target
    if $button.hasClass 'section-visible'
      $button.toggleClass 'section-visible', no
      Factory.trigger 'toggleslides', 'hide'
    else
      $button.toggleClass 'section-visible', yes
      Factory.trigger 'toggleslides', 'show'

# ---

# Boot it up
$ ->
  Factory.Editor        = new Editor el: $('.writing textarea')
  Factory.SlideViewer   = new SlideViewer el: $('.slide-container')
  Factory.SlidesBrowser = new SlidesBrowser el: $('.authoring .slides')
  Factory.MainMenu      = new MainMenu el: $('.authoring menu')

  Factory.trigger 'editor:updated', $('.writing textarea').val()
  Factory.SlidesBrowser.addSlide $('.slide')
