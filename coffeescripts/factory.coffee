# Factory - Interactions
# ======================

# Keep a global reference around, as well as some app-wide methods.
window.Factory =

  # Opens a presentation object. You can open at a slide directly
  # by passing a number to it
  open: (presentation, slideNumber = 0) ->
    @_unbindComponents @currentPresentation if @currentPresentation?
    @_setCurrent presentation, slideNumber
    @_bindComponents @currentPresentation
    Factory.Editor.open presentation.slideAt slideNumber
    Factory.SlideViewer.createSlide presentation.slideAt slideNumber
    Factory.SlidesBrowser.loadSlides presentation.get 'slides'
    Factory.Settings.save
      editing: { id: presentation.id, slideNumber: slideNumber }

  # Bind a presentation to the components
  _bindComponents: (presentation) ->
    presentation.on 'change', ->
      Factory.SlidesBrowser.loadSlides presentation.get 'slides'

  # Unbinds a presentation from the components
  _unbindComponents: (presentation) ->
    presentation.off()

  # Sets the current presentation and slide number
  _setCurrent: (presentation, slideNumber) ->
    @currentPresentation = presentation
    @currentSlide = slideNumber

  # Saves what's in the text editor to the current slide in the
  # current presentation
  saveCurrentPresentation: ->
    slides = @currentPresentation.get('slides')
    slides[@currentSlide] = Factory.Editor.$el.val()
    @currentPresentation.save 'slides': slides
    # localStorage events won't fire in the same window, so for now
    # there's no other way
    Factory.Browser.loadPresentations()

  # Switches off editing, hiding the components and enabling left
  # and right arrows.
  play: ->
    $body.removeClass 'editing'

# ---

# Cache a reference of the document and it's body
$document = $ document
$body     = $ 'body'

DEFAULT_SLIDE = """
  # Introducing Factory

  Factory is an in-browser slide creation and
  publishing tool.

  No server setup required. Slides are served straight from
  your browser.
"""

# ---

# Assorted helpers

# Ensures local links behave nicely by allowing the user to
# open them in a new tab
catchLinkClicks = ->
  $(document).on 'click', 'a', (event) ->
    $link = $ event.target
    if $link.is 'a[href^="/"]'
      return if event.metaKey
      event.preventDefault()
      Factory.Router.navigate $link.attr('href'), true

# Backbone.Model drop in sync() method that saves a model to
# localStorage
localStorageSync = (method, model, rest...) ->
  switch method
    when 'create', 'update'
      localStorage.setItem @id, JSON.stringify model
      model.trigger 'change'
    when 'delete'
      localStorage.removeItem @id
    when 'read'
      attributes = localStorage.getItem @id
      model.attributes = JSON.parse attributes if attributes?
      model.trigger 'reset'
  @

# ---

# The in-browser HTTP server
server = http.createServer()

server.once 'request', (req) ->
  console.log "CONNECTED: #{req.headers.host}"

server.on 'request', (req, res) ->
  if req.method isnt 'GET'
    res.writeHead 405, 'Content-Type': 'text/plain'
    return res.end 'Method not allowed'

  res.writeHead 200, 'Content-Type': 'text/plain'
  res.end 'Hola'

Factory.Server = server

# ---

# The slide text editor
class Editor extends Backbone.View

  # Ignore these keys when pressed in the textarea
  keysBlacklist: [
    16, 17, 18, 20 # SHIFT, CTRL, ALT, CAPS LOCK
    37, 38, 39, 40 # Keyboard arrows
  ]

  initialize: ->
    @trackTextAreaChanges()

  # Opens a slide's markdown
  open: (markdown) ->
    @$el.val markdown

  # Tracks changes made in the editor, and updates the current
  # slide in the stage and saves the current presentation once
  # you stop typing for 1s
  trackTextAreaChanges: ->
    @_debouncedSave ?= _.debounce ->
      Factory.saveCurrentPresentation()
    , 250
    @$el.on 'keyup change cut paste', (event) =>
      return if event.keyCode in @keysBlacklist
      Factory.SlideViewer.updateSlide @$el.val()
      @_debouncedSave()
    # TAB needs to be trapped on keydown
    @$el.on 'keydown', (event) =>
      if event.keyCode is 9 #
        event.preventDefault()
        @addTab event.target

  # Adds a tab where the cursor is when TAB is pressed.
  addTab: (textarea) ->
    start = textarea.selectionStart
    end = textarea.selectionEnd
    $textarea = $ textarea
    markdown = $textarea.val()

    $textarea.val [
      markdown.substring(0, start)
      "  "
      markdown.substring(end)
    ].join ''

    textarea.selectionStart = textarea.selectionEnd = start + 2

# ---

# The right-hand part where the current slide gets shown.
class SlideViewer extends Backbone.View

  initialize: ->
    @bindNavigationKeys()

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

  # Binds left and right arrow keys to back/forward slides
  bindNavigationKeys: ->
    $document.on 'keyup', (event) =>
      return if @isEditing()
      @nextSlide() if event.keyCode is 39
      @previousSlide() if event.keyCode is 37

  # True/false if Factory is in editing mode or not
  isEditing: ->
    $body.is '.editing'

  # Navigates to the next slide
  nextSlide: ->
    presentation = Factory.currentPresentation
    currentSlide = Factory.currentSlide
    slides = presentation.get 'slides'
    return false if currentSlide+1 is slides.length
    Factory.Router.navigate presentation.url(++currentSlide), true

  # Navigates to the previous slide
  previousSlide: ->
    presentation = Factory.currentPresentation
    currentSlide = Factory.currentSlide
    slides = presentation.get 'slides'
    return false if currentSlide is 0
    Factory.Router.navigate presentation.url(--currentSlide), true

# ---

# The slides browser
class SlidesBrowser extends Backbone.View

  events:
    'click a button': 'clickDelete'

  # Slide entry template
  template: _.template $('#slides-browser-entry').html()

  # Adds a slide to the list of slides
  addSlide: (markdown) ->
    index = @$el.find('a').length
    $a = $ @template
      summary: @makeSummary markdown
      url: Factory.currentPresentation.url index
    @$el.append $a

  # Callback for handling clicking the delete icon in a
  # slide link
  clickDelete: (event) ->
    event.preventDefault()
    event.stopPropagation()
    @deleteSlide $(event.target).parent('a').index()

  # Deletes a slide by index in the `attributes.slides` array
  deleteSlide: (slideNumber) ->
    presentation = Factory.currentPresentation
    slides = presentation.get 'slides'
    slides.splice slideNumber, 1
    presentation.save 'slides': slides
    if Factory.currentSlide is slideNumber
      previous = slideNumber - 1
      url = if previous < 0
              presentation.url()
            else
              presentation.url previous
      Factory.Router.navigate url, true

  # Loads an array of slides into the list, clearing the
  # existing ones.
  loadSlides: (slides) ->
    @$el.empty()
    @addSlide slide for slide in slides

  # Toggles the slides list visibility
  toggleVisible: ->
    if @$el.is ':visible'
      @$el.fadeOut 100
    else
      @$el.fadeIn 150

  # Grabs some text from a slide's compiled markdown
  # so @addSlide can show a preview
  makeSummary: (markdown) ->
    $placeholder = $('<div></div>').html marked markdown
    $placeholder.find('*:first').text()

  # Clears all slide entries
  empty: ->
    @$el.find('li').remove()

# ---

# The app's main menu
class MainMenu extends Backbone.View

  events:
    'click .play'                 : 'play'
    'click .show-slides'          : 'toggleSlides'
    'click .new-slide'            : 'createNewSlide'
    'click .delete-presentation'  : 'deletePresentation'
    'click .browse-presentations' : 'togglePresentationsBrowser'


  initialize: ->
    # We'll step out of our element for the sake of relevance
    $('.overlay').click @togglePresentationsBrowser

  # Controls whether the show/hide slides button has/hasn't
  # a "section-visible" class, and gets Factory to fire slides:toggle
  toggleSlides: ->
    $button = $ event.target
    $button.toggleClass 'section-visible'
    Factory.SlidesBrowser.toggleVisible()

  # Creates a new slide by calling addSlide() on a Presentation
  # instance
  createNewSlide: ->
    presentation = Factory.currentPresentation
    presentation.addSlide DEFAULT_SLIDE

  # Deletes the current presentation upon confirmation
  deletePresentation: ->
    if confirm "Delete this presentation?"
      Factory.currentPresentation.destroy()
      Factory.Router.navigate '/new', true

  # Shows/hides the presentation browser
  togglePresentationsBrowser: ->
    Factory.Browser.toggleVisible()

  play: Factory.play

# ---

# The presentation model. We won't need a collection for these
# as we'll be using localStorage for that
class Presentation extends Backbone.Model

  # Class method to grab a presentation from localStorage
  @find: (id) ->
    if localStorage[id]?
      presentation = new Presentation id: id
      presentation.fetch()
      presentation

  # Use localStorage to store models as localStorage[<model id>]
  sync: localStorageSync

  initialize: ->
    if @isNew()
      @set 'id': @makeUniqueId(), created: new Date
      @addSlide DEFAULT_SLIDE

  # Makes something less long than a UUID
  makeUniqueId: ->
    Math.random().toString(36).substring(6).toUpperCase()

  # Returns the slide at index `slideNumber`
  slideAt: (slideNumber) ->
    @get('slides')[slideNumber] if @has 'slides'

  # Adds a slide's markdown to the array of slides
  addSlide: (markdown) ->
    if @has 'slides'
      slides = @get 'slides'
      slides.push markdown
      @save 'slides': slides
    else
      @save 'slides', [markdown]

  # Helper to construct a URL for a presentation. Passing
  # a slide number adds a direct link to it.
  url: (slideNumber) ->
    url = "/#{@id}"
    url += "/#{slideNumber}" if slideNumber?
    url

  # Returns a "title" for the presentation, assuming the first thing
  # you mentioned is something that could be used as such
  title: ->
    if @get('slides').length isnt 0
      $placeholder = $('<div></div>').html marked @get('slides')[0]
      $placeholder.find('*:first').text()

  # Returns the presentation's creation date in human readable form
  prettyCreationDate: ->
    if createdAt = new Date @get('created')
      moment(createdAt).format "MMMM Do YYYY, h:mm:ssa"

# ---

# The presentations browser, so you can navigate all the presentations
# kept in localStorage
class PresentationsBrowser extends Backbone.View

  events:
    'click li' : 'clickOpen'

  template: _.template $('#presentations-browser-entry').html()

  # Since localStorage is ready as soon as the browser opens, it's
  # safe to load what's in it as soon as we instance the browser.
  initialize: ->
    @loadPresentations()

  # Loads all presentations that exist in localStorage onto the
  # presentations browser, clearing any existing ones from display
  loadPresentations: ->
    @$el.empty()
    for presentationId in _.keys localStorage
      continue if presentationId in ['Settings', 'debug']
      @add Presentation.find presentationId

  # Adds a single presentation model instance to the presentations
  # browser
  add: (presentation) ->
    $template = $ @template presentation
    $template.find('.preview').append @makeFirstSlideThumb presentation
    @$el.append $template

  # Opens a presentation, hiding the presentations browser in the process
  clickOpen: (event) ->
    $li = $(event.target).closest 'li'
    if presentation = Presentation.find $li.data 'presentation-id'
      @toggleVisible()
      Factory.Router.navigate presentation.url(), true

  # Creates a "thumbnail" for the first slide in a presentation
  makeFirstSlideThumb: (presentation) ->
    slides = presentation.get 'slides'
    if slides.length isnt 0
      @make 'div',
        class: 'slide-thumb',
        marked slides[0]

  # Toggles visibility, which in order to achieve the desired effect,
  # it consists of toggling classes outside of this component
  toggleVisible: ->
    $body.toggleClass 'far'
    $('.overlay').toggle()

# ---

# App settings, including some handy variables such as what
# presentation where we looking at last
class Settings extends Backbone.Model

  # Always find it in localStorage['Settings']
  id: 'Settings'

  # Keep settings in localStorage
  sync: localStorageSync

# ---

# Sadly, this since is a self-contained client-side app, we'll
# need Backbone.Router
class Router extends Backbone.Router

  routes:
    ''           : 'home'
    'new'        : 'new'
    ':id'        : 'open'
    ':id/:slide' : 'open'

  # If there's any presentation recorded as the last being edited
  # in Factory.Settings, open it, otherwise create a new one
  home: ->
    editing = Factory.Settings.attributes.editing
    if editing?
      presentation = Presentation.find editing.id
      @navigate presentation.url editing.slideNumber, true
    else
      @navigate '/new', true

  # Opens a presentation. If a slide number is provided, jump
  # to it
  open: (presentationId, slideNumber = 0) ->
    if presentation = Presentation.find presentationId
      Factory.open presentation, +slideNumber

  # Creates a new presentation and opens it by navigating to
  # it's URL
  new: ->
    @navigate (new Presentation).url(), true

# ---

# Boot it up
$ ->
  Factory.Editor        = new Editor el: $('.writing textarea')
  Factory.SlideViewer   = new SlideViewer el: $('.slide-container')
  Factory.SlidesBrowser = new SlidesBrowser el: $('.authoring .slides')
  Factory.MainMenu      = new MainMenu el: $('.authoring menu')
  Factory.Browser       = new PresentationsBrowser el: $('.presentations-browser')
  Factory.Settings      = new Settings
  Factory.Router        = new Router

  # Create a new WebSocket connection
  socket = new eio.Socket host: location.hostname, port: location.port

  # Listen to connections coming from the server
  Factory.Server.listen socket

  # Ensure settings are loaded
  Factory.Settings.fetch()

  # Fix link clicks (see Helpers at the top)
  catchLinkClicks()

  # Start Backbone.Router
  Backbone.history.start pushState: true
