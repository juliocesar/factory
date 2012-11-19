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
  open: (presentation, slideNumber = 0) ->
    @currentPresentation = presentation
    @currentSlide = slideNumber
    markdown = @currentPresentation.get('slides')[slideNumber]
    Factory.Editor.open markdown
    Factory.SlideViewer.createSlide markdown
    Factory.SlidesBrowser.loadSlides @currentPresentation.get('slides')

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
    @trackTextAreaChanges()

  # Opens a slide's markdown
  open: (markdown) ->
    @$el.val markdown

  # Tracks changes made in the editor and fires editor:updated
  trackTextAreaChanges: ->
    @$el.on 'keyup change cut paste', =>
      Factory.trigger 'editor:updated', @$el.val()

# ---

# The right-hand part where the current slide gets shown.
class SlideViewer extends Backbone.View

  initialize: ->
    Factory.on 'editor:updated', (markdown) =>
      @updateSlide markdown
    Factory.on 'slide:added', (markdown) =>
      @createSlide markdown

  # Creates a new slide
  createSlide: (markdown) ->
    @$el.empty()
    @_currentSlide = $slide = $ @make 'div', class: 'slide'
    @$el.append $slide
    @updateSlide markdown

  # Memoizes and returns the current slide's element
  currentSlide: ->
    @_currentSlide ?= @$el.find '.slide'

  # Compiles markdown from the text editor using marked()
  # and prints the markup to the stage
  updateSlide: (markdown) ->
    @currentSlide().html marked markdown

# ---

# The slides browser
class SlidesBrowser extends Backbone.View

  events:
    'click a': 'open'

  # Slide entry template
  template: _.template """
    <a href="<%= url %>" class="icon-star">
      <%= summary %>
      <button class="delete icon-trash"></button>
    </a>
  """

  initialize: ->
    Factory.on 'slide:added', (markdown) =>
      @addSlide markdown
    Factory.on 'slides:toggle', (showOrHide) =>
      @toggleVisible showOrHide

  # Opens a slide when clicking it. Won't do anything if
  # command+click is pressed, thus being new tab friendly
  open: (event) ->
    return if event.metaKey
    event.preventDefault()
    $link = $ event.target
    Factory.Router.navigate $link.attr('href'), true

  # Adds a slide to the list of slides
  addSlide: (markdown) ->
    index = @$el.find('a').length
    $a = $ @template
      summary: @makeSummary markdown
      url: Factory.currentPresentation.url index
    @$el.append $a

  # Loads an array of slides into the list, clearing the
  # existing ones.
  loadSlides: (slides) ->
    @$el.empty()
    @addSlide slide for slide in slides

  # Shows or hides the slides list. Pass 'show' to show,
  # or 'hide' to hide
  toggleVisible: (showOrHide) ->
    if showOrHide is 'show'
      @$el.fadeIn 250
    else if 'hide'
      @$el.fadeOut 100

  # Grabs some text from a slide's compiled markdown
  # so @addSlide can show a preview
  makeSummary: (markdown) ->
    $placeholder = $('<div></div>').html marked markdown
    $placeholder.find('*:first-child').text()

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

# The presentation model. We won't need a collection for these
# as we'll be using localStorage for that.
class Presentation extends Backbone.Model

  # Class method to grab a presentation from localStorage
  @find: (id) ->
    if localStorage[id]?
      presentation = new Presentation id: id
      presentation.fetch()
      presentation

  initialize: ->
    if @isNew()
      @set 'id': @makeUniqueId()
      @addSlide DEFAULT_SLIDE

  # Makes something less long than a UUID
  makeUniqueId: ->
    Math.random().toString(36).substring(6).toUpperCase()

  # Adds a slide's markdown to the array of slides
  addSlide: (markdown) ->
    if @has 'slides'
      slides = @get 'slides'
      slides.push markdown
      @save 'slides': slides
    else
      @set 'slides', [markdown]
    Factory.trigger 'slide:added', markdown

  # Helper to construct a URL for a presentation. Passing
  # a slide number adds a direct link to it.
  url: (slideNumber) ->
    url = "/#{@id}"
    url += "/#{slideNumber}" if slideNumber?
    url

  # Use localStorage to store models as localStorage[<model id>]
  sync: (method, model, rest...) ->
    switch method
      when 'create', 'update'
        localStorage.setItem @id, JSON.stringify model
      when 'delete'
        localStorage.removeItem @id
      when 'read'
        attributes = localStorage.getItem @id
        model.attributes = JSON.parse attributes if attributes?
        model
    @

# ---

# Sadly, this since is a self-contained client-side app, we'll
# need Backbone.Router
class Router extends Backbone.Router

  routes:
    ''           : 'home'
    'new'        : 'new'
    ':id'        : 'open'
    ':id/:slide' : 'open'

  home: ->
    @navigate '/new', true

  # Opens a presentation. If a slide number is provided, jump
  # to it
  open: (presentationId, slideNumber = 0) ->
    if presentation = Presentation.find presentationId
      Factory.open presentation, slideNumber

  # Creates a new presentation
  new: ->
    Factory.open new Presentation, 0

# ---

# Boot it up
$ ->
  Factory.Editor        = new Editor el: $('.writing textarea')
  Factory.SlideViewer   = new SlideViewer el: $('.slide-container')
  Factory.SlidesBrowser = new SlidesBrowser el: $('.authoring .slides')
  Factory.MainMenu      = new MainMenu el: $('.authoring menu')
  Factory.Router        = new Router

  Backbone.history.start pushState: true
