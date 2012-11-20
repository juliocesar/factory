# Factory - Interactions
# ======================

# Keep a global reference around, as well as some app-wide methods.
window.Factory =

  # Opens a presentation object.
  open: (presentation, slideNumber = 0) ->
    @_unbindComponents @currentPresentation if @currentPresentation?
    @_setCurrent presentation, slideNumber
    @_bindComponents @currentPresentation
    markdown = presentation.get('slides')[slideNumber]
    Factory.Editor.open markdown
    Factory.SlideViewer.createSlide markdown
    @currentPresentation.trigger 'change'

  # Bind a presentation to the components
  _bindComponents: (presentation) ->
    presentation.on 'change', ->
      Factory.SlidesBrowser.loadSlides presentation.get 'slides'

  # Unbinds a presentation from the components
  _unbindComponents: (presentation) ->
    presentation.off()

  # Sets the current presentation and slide
  _setCurrent: (presentation, slideNumber) ->
    @currentPresentation = presentation
    @currentSlide = slideNumber

  # Saves what's in the text editor to the current slide in the
  # current presentation
  saveCurrentPresentation: ->
    slides = @currentPresentation.get('slides')
    slides[@currentSlide] = Factory.Editor.$el.val()
    @currentPresentation.save 'slides': slides
    @currentPresentation.trigger 'change'

# Make it the components events hub
_.extend Factory, Backbone.Events

DEFAULT_SLIDE = """
  # Introducing Factory

  Factory is an in-browser slide creation and
  publishing tool.

  No server setup required. Slides are served straight from
  your browser.
"""

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
    , 1000
    @$el.on 'keyup change cut paste', (event) =>
      return if event.keyCode in @keysBlacklist
      Factory.SlideViewer.updateSlide @$el.val()
      @_debouncedSave()
    @$el.on 'keydown', (event) =>
      if event.keyCode is 9
        event.preventDefault()
        return @addTab event.target

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
    'click a button': 'clickDelete'

  # Slide entry template
  template: _.template """
    <a href="<%= url %>" class="icon-star">
      <%= summary %>
      <button class="delete icon-trash"></button>
    </a>
  """

  initialize: ->
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

  clickDelete: (event) ->
    event.preventDefault()
    event.stopPropagation()
    console.log "DELETING: #{$(event.target).parent('a').index()}"
    @deleteSlide $(event.target).parent('a').index()

  deleteSlide: (slideNumber) ->
    presentation = Factory.currentPresentation
    presentation.set 'slides':
      presentation.attributes.slides.splice(slideNumber, 1)
    Factory.saveCurrentPresentation()

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

  # Clears all slide entries
  empty: ->
    @$el.find('li').remove()

# ---

# The app's main menu
class MainMenu extends Backbone.View

  events:
    'click .show-slides' : 'toggleSlides'
    'click .new-slide'   : 'createNewSlide'

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

  # Creates a new slide by calling addSlide() on a Presentation
  # instance
  createNewSlide: ->
    presentation = Factory.currentPresentation
    presentation.addSlide DEFAULT_SLIDE

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
      @save 'slides', [markdown]
    @trigger 'change'

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

  # Creates a new presentation and opens the first slide in
  # it (number zero)
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
