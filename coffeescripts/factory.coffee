# Factory - Interactions
# ======================
#
# The gist:
#
# * Each Backbone view is a component that binds to a DOM element
#   that already exists by the time the app is instantiated.
# * Components talk to each other by triggering events and passing
#   data to the global `Factory` object, and by listening to events
#   on it, so views never talk to each other directly.

# Keep a global reference around, as well as some app-wide methods.
window.Factory =
  # Opens a presentation object.
  open: (presentation) ->
    Factory.Editor.loadFixture()
    Factory.SlidesBrowser.empty()
    Factory.SlideViewer.createNewSlide()

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
    Factory.on 'slide:request', => @loadFixture()
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
    Factory.on 'slide:request', => @createNewSlide()
    Factory.on 'editor:updated', (markdown) =>
      @updateSlide markdown

  # Creates a new slide
  createNewSlide: ->
    @$el.empty()
    @_currentSlide = $slide = $ @make 'div', class: 'slide'
    @$el.append $slide
    @updateSlide DEFAULT_SLIDE
    Factory.trigger 'slide:new', $slide

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
    Factory.on 'slide:new', ($slide) => @addSlide $slide
    Factory.on 'slides:toggle', (showOrHide) =>
      @toggleVisible showOrHide

  # Adds a slide to the list of slides
  addSlide: ($slide) ->
    $li = $ @template summary: @makeSummary($slide)
    @$el.append $li

  # Shows or hides the slides list. Pass 'show' to show,
  # or 'hide' to hide
  toggleVisible: (showOrHide) ->
    if showOrHide is 'show'
      @$el.fadeIn 250
    else if 'hide'
      @$el.fadeOut 100

  # Grabs some text from a slide so @addSlide can show
  # a preview
  makeSummary: ($slide) ->
    $slide.find('*:first-child').text()

  empty: ->
    @$el.find('li').remove()

# ---

# The app's main menu
class MainMenu extends Backbone.View
  events:
    'click .show-slides' : 'toggleSlides'
    'click .new-slide'   : 'requestNewSlide'

  # Controls whether the show/hide slides button has/hasn't
  # a "section-visible" class, and gets Factory to fire slides:toggle
  toggleSlides: ->
    $button = $ event.target
    if $button.hasClass 'section-visible'
      $button.toggleClass 'section-visible', no
      Factory.trigger 'slides:toggle', 'hide'
    else
      $button.toggleClass 'section-visible', yes
      Factory.trigger 'slides:toggle', 'show'

  requestNewSlide: ->
    Factory.trigger 'slide:request'

# ---

# We'll use localStorage to keep presentations like this:
# localStorage['XXXXX'] = <serialized slides>
# localStorage['AABBB'] = <serialized slides>
class Presentation extends Backbone.Model
  initialize: ->
    @set 'id', @makeUniqueId()
    @localStorage = new Backbone.LocalStorage @id

  makeUniqueId: ->
    Math.random().toString(36).substring(6).toUpperCase()

# ---

# Sadly, this since is a self-contained client-side app, we'll
# need Backbone.Router
class Router extends Backbone.Router
  routes:
    ''           : 'home'
    'new'        : 'new'
    ':id'        : 'open'
    ':id/:slide' : 'openSlide'

  home: ->
    @navigate '/new', true

  new: ->
    Factory.open new Presentation

# ---

# Boot it up
$ ->
  Factory.Editor        = new Editor el: $('.writing textarea')
  Factory.SlideViewer   = new SlideViewer el: $('.slide-container')
  Factory.SlidesBrowser = new SlidesBrowser el: $('.authoring .slides')
  Factory.MainMenu      = new MainMenu el: $('.authoring menu')

  # Instance a router in the void. We won't be needing it further.
  new Router

  Backbone.history.start pushState: true
