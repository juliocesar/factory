// Generated by CoffeeScript 1.3.3
(function() {
  var DEFAULT_SLIDE, Editor, MainMenu, Presentation, PresentationsBrowser, Router, Settings, SlideViewer, SlidesBrowser, catchLinkClicks, localStorageSync,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  window.Factory = {
    open: function(presentation, slideNumber) {
      if (slideNumber == null) {
        slideNumber = 0;
      }
      if (this.currentPresentation != null) {
        this._unbindComponents(this.currentPresentation);
      }
      this._setCurrent(presentation, slideNumber);
      this._bindComponents(this.currentPresentation);
      Factory.Editor.open(presentation.slideAt(slideNumber));
      Factory.SlideViewer.createSlide(presentation.slideAt(slideNumber));
      Factory.SlidesBrowser.loadSlides(presentation.get('slides'));
      return Factory.Settings.save({
        editing: {
          id: presentation.id,
          slideNumber: slideNumber
        }
      });
    },
    _bindComponents: function(presentation) {
      return presentation.on('change', function() {
        return Factory.SlidesBrowser.loadSlides(presentation.get('slides'));
      });
    },
    _unbindComponents: function(presentation) {
      return presentation.off();
    },
    _setCurrent: function(presentation, slideNumber) {
      this.currentPresentation = presentation;
      return this.currentSlide = slideNumber;
    },
    saveCurrentPresentation: function() {
      var slides;
      slides = this.currentPresentation.get('slides');
      slides[this.currentSlide] = Factory.Editor.$el.val();
      this.currentPresentation.save({
        'slides': slides
      });
      return Factory.Browser.loadPresentations();
    }
  };

  DEFAULT_SLIDE = "# Introducing Factory\n\nFactory is an in-browser slide creation and\npublishing tool.\n\nNo server setup required. Slides are served straight from\nyour browser.";

  catchLinkClicks = function() {
    return $(document).on('click', 'a', function(event) {
      var $link;
      $link = $(event.target);
      if ($link.is('a[href^="/"]')) {
        if (event.metaKey) {
          return;
        }
        event.preventDefault();
        return Factory.Router.navigate($link.attr('href'), true);
      }
    });
  };

  localStorageSync = function() {
    var attributes, method, model, rest;
    method = arguments[0], model = arguments[1], rest = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
    switch (method) {
      case 'create':
      case 'update':
        localStorage.setItem(this.id, JSON.stringify(model));
        model.trigger('change');
        break;
      case 'delete':
        localStorage.removeItem(this.id);
        break;
      case 'read':
        attributes = localStorage.getItem(this.id);
        if (attributes != null) {
          model.attributes = JSON.parse(attributes);
        }
        model.trigger('reset');
    }
    return this;
  };

  Factory.Server = http.createServer(function(req, res) {
    if (req.method !== 'GET') {
      res.writeHead(405, {
        'Content-Type': 'text/plain'
      });
      return res.end('Method not allowed');
    }
    res.writeHead(200, {
      'Content-Type': 'text/plain'
    });
    return res.end('Hola');
  });

  Editor = (function(_super) {

    __extends(Editor, _super);

    function Editor() {
      return Editor.__super__.constructor.apply(this, arguments);
    }

    Editor.prototype.keysBlacklist = [16, 17, 18, 20, 37, 38, 39, 40];

    Editor.prototype.initialize = function() {
      return this.trackTextAreaChanges();
    };

    Editor.prototype.open = function(markdown) {
      return this.$el.val(markdown);
    };

    Editor.prototype.trackTextAreaChanges = function() {
      var _ref,
        _this = this;
      if ((_ref = this._debouncedSave) == null) {
        this._debouncedSave = _.debounce(function() {
          return Factory.saveCurrentPresentation();
        }, 250);
      }
      this.$el.on('keyup change cut paste', function(event) {
        var _ref1;
        if (_ref1 = event.keyCode, __indexOf.call(_this.keysBlacklist, _ref1) >= 0) {
          return;
        }
        Factory.SlideViewer.updateSlide(_this.$el.val());
        return _this._debouncedSave();
      });
      return this.$el.on('keydown', function(event) {
        if (event.keyCode === 9) {
          event.preventDefault();
          return _this.addTab(event.target);
        }
      });
    };

    Editor.prototype.addTab = function(textarea) {
      var $textarea, end, markdown, start;
      start = textarea.selectionStart;
      end = textarea.selectionEnd;
      $textarea = $(textarea);
      markdown = $textarea.val();
      $textarea.val([markdown.substring(0, start), "  ", markdown.substring(end)].join(''));
      return textarea.selectionStart = textarea.selectionEnd = start + 2;
    };

    return Editor;

  })(Backbone.View);

  SlideViewer = (function(_super) {

    __extends(SlideViewer, _super);

    function SlideViewer() {
      return SlideViewer.__super__.constructor.apply(this, arguments);
    }

    SlideViewer.prototype.createSlide = function(markdown) {
      var $slide;
      this.$el.empty();
      this._currentSlide = $slide = $(this.make('div', {
        "class": 'slide'
      }));
      this.$el.append($slide);
      return this.updateSlide(markdown);
    };

    SlideViewer.prototype.currentSlide = function() {
      var _ref;
      return (_ref = this._currentSlide) != null ? _ref : this._currentSlide = this.$el.find('.slide');
    };

    SlideViewer.prototype.updateSlide = function(markdown) {
      return this.currentSlide().html(marked(markdown));
    };

    return SlideViewer;

  })(Backbone.View);

  SlidesBrowser = (function(_super) {

    __extends(SlidesBrowser, _super);

    function SlidesBrowser() {
      return SlidesBrowser.__super__.constructor.apply(this, arguments);
    }

    SlidesBrowser.prototype.events = {
      'click a button': 'clickDelete'
    };

    SlidesBrowser.prototype.template = _.template($('#slides-browser-entry').html());

    SlidesBrowser.prototype.addSlide = function(markdown) {
      var $a, index;
      index = this.$el.find('a').length;
      $a = $(this.template({
        summary: this.makeSummary(markdown),
        url: Factory.currentPresentation.url(index)
      }));
      return this.$el.append($a);
    };

    SlidesBrowser.prototype.clickDelete = function(event) {
      event.preventDefault();
      event.stopPropagation();
      return this.deleteSlide($(event.target).parent('a').index());
    };

    SlidesBrowser.prototype.deleteSlide = function(slideNumber) {
      var presentation, previous, slides, url;
      presentation = Factory.currentPresentation;
      slides = presentation.get('slides');
      slides.splice(slideNumber, 1);
      presentation.save({
        'slides': slides
      });
      if (Factory.currentSlide === slideNumber) {
        previous = slideNumber - 1;
        url = previous < 0 ? presentation.url() : presentation.url(previous);
        return Factory.Router.navigate(url, true);
      }
    };

    SlidesBrowser.prototype.loadSlides = function(slides) {
      var slide, _i, _len, _results;
      this.$el.empty();
      _results = [];
      for (_i = 0, _len = slides.length; _i < _len; _i++) {
        slide = slides[_i];
        _results.push(this.addSlide(slide));
      }
      return _results;
    };

    SlidesBrowser.prototype.toggleVisible = function() {
      if (this.$el.is(':visible')) {
        return this.$el.fadeOut(100);
      } else {
        return this.$el.fadeIn(150);
      }
    };

    SlidesBrowser.prototype.makeSummary = function(markdown) {
      var $placeholder;
      $placeholder = $('<div></div>').html(marked(markdown));
      return $placeholder.find('*:first').text();
    };

    SlidesBrowser.prototype.empty = function() {
      return this.$el.find('li').remove();
    };

    return SlidesBrowser;

  })(Backbone.View);

  MainMenu = (function(_super) {

    __extends(MainMenu, _super);

    function MainMenu() {
      return MainMenu.__super__.constructor.apply(this, arguments);
    }

    MainMenu.prototype.events = {
      'click .show-slides': 'toggleSlides',
      'click .new-slide': 'createNewSlide',
      'click .delete-presentation': 'deletePresentation',
      'click .browse-presentations': 'togglePresentationsBrowser'
    };

    MainMenu.prototype.initialize = function() {
      return $('.overlay').click(this.togglePresentationsBrowser);
    };

    MainMenu.prototype.toggleSlides = function() {
      var $button;
      $button = $(event.target);
      $button.toggleClass('section-visible');
      return Factory.SlidesBrowser.toggleVisible();
    };

    MainMenu.prototype.createNewSlide = function() {
      var presentation;
      presentation = Factory.currentPresentation;
      return presentation.addSlide(DEFAULT_SLIDE);
    };

    MainMenu.prototype.deletePresentation = function() {
      if (confirm("Delete this presentation?")) {
        Factory.currentPresentation.destroy();
        return Factory.Router.navigate('/new', true);
      }
    };

    MainMenu.prototype.togglePresentationsBrowser = function() {
      return Factory.Browser.toggleVisible();
    };

    return MainMenu;

  })(Backbone.View);

  Presentation = (function(_super) {

    __extends(Presentation, _super);

    function Presentation() {
      return Presentation.__super__.constructor.apply(this, arguments);
    }

    Presentation.find = function(id) {
      var presentation;
      if (localStorage[id] != null) {
        presentation = new Presentation({
          id: id
        });
        presentation.fetch();
        return presentation;
      }
    };

    Presentation.prototype.sync = localStorageSync;

    Presentation.prototype.initialize = function() {
      if (this.isNew()) {
        this.set({
          'id': this.makeUniqueId(),
          created: new Date
        });
        return this.addSlide(DEFAULT_SLIDE);
      }
    };

    Presentation.prototype.makeUniqueId = function() {
      return Math.random().toString(36).substring(6).toUpperCase();
    };

    Presentation.prototype.slideAt = function(slideNumber) {
      if (this.has('slides')) {
        return this.get('slides')[slideNumber];
      }
    };

    Presentation.prototype.addSlide = function(markdown) {
      var slides;
      if (this.has('slides')) {
        slides = this.get('slides');
        slides.push(markdown);
        return this.save({
          'slides': slides
        });
      } else {
        return this.save('slides', [markdown]);
      }
    };

    Presentation.prototype.url = function(slideNumber) {
      var url;
      url = "/" + this.id;
      if (slideNumber != null) {
        url += "/" + slideNumber;
      }
      return url;
    };

    Presentation.prototype.title = function() {
      var $placeholder;
      if (this.get('slides').length !== 0) {
        $placeholder = $('<div></div>').html(marked(this.get('slides')[0]));
        return $placeholder.find('*:first').text();
      }
    };

    Presentation.prototype.prettyCreationDate = function() {
      var createdAt;
      if (createdAt = new Date(this.get('created'))) {
        return moment(createdAt).format("MMMM Do YYYY, h:mm:ssa");
      }
    };

    return Presentation;

  })(Backbone.Model);

  PresentationsBrowser = (function(_super) {

    __extends(PresentationsBrowser, _super);

    function PresentationsBrowser() {
      return PresentationsBrowser.__super__.constructor.apply(this, arguments);
    }

    PresentationsBrowser.prototype.events = {
      'click li': 'clickOpen'
    };

    PresentationsBrowser.prototype.template = _.template($('#presentations-browser-entry').html());

    PresentationsBrowser.prototype.initialize = function() {
      return this.loadPresentations();
    };

    PresentationsBrowser.prototype.loadPresentations = function() {
      var presentationId, _i, _len, _ref, _results;
      this.$el.empty();
      _ref = _.keys(localStorage);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        presentationId = _ref[_i];
        if (presentationId === 'Settings' || presentationId === 'debug') {
          continue;
        }
        _results.push(this.add(Presentation.find(presentationId)));
      }
      return _results;
    };

    PresentationsBrowser.prototype.add = function(presentation) {
      var $template;
      $template = $(this.template(presentation));
      $template.find('.preview').append(this.makeFirstSlideThumb(presentation));
      return this.$el.append($template);
    };

    PresentationsBrowser.prototype.clickOpen = function(event) {
      var $li, presentation;
      $li = $(event.target).closest('li');
      if (presentation = Presentation.find($li.data('presentation-id'))) {
        this.toggleVisible();
        return Factory.Router.navigate(presentation.url(), true);
      }
    };

    PresentationsBrowser.prototype.makeFirstSlideThumb = function(presentation) {
      var slides;
      slides = presentation.get('slides');
      if (slides.length !== 0) {
        return this.make('div', {
          "class": 'slide-thumb'
        }, marked(slides[0]));
      }
    };

    PresentationsBrowser.prototype.toggleVisible = function() {
      $('body').toggleClass('far');
      return $('.overlay').toggle();
    };

    return PresentationsBrowser;

  })(Backbone.View);

  Settings = (function(_super) {

    __extends(Settings, _super);

    function Settings() {
      return Settings.__super__.constructor.apply(this, arguments);
    }

    Settings.prototype.id = 'Settings';

    Settings.prototype.sync = localStorageSync;

    return Settings;

  })(Backbone.Model);

  Router = (function(_super) {

    __extends(Router, _super);

    function Router() {
      return Router.__super__.constructor.apply(this, arguments);
    }

    Router.prototype.routes = {
      '': 'home',
      'new': 'new',
      ':id': 'open',
      ':id/:slide': 'open'
    };

    Router.prototype.home = function() {
      var editing, presentation;
      editing = Factory.Settings.attributes.editing;
      if (editing != null) {
        presentation = Presentation.find(editing.id);
        return this.navigate(presentation.url(editing.slideNumber, true));
      } else {
        return this.navigate('/new', true);
      }
    };

    Router.prototype.open = function(presentationId, slideNumber) {
      var presentation;
      if (slideNumber == null) {
        slideNumber = 0;
      }
      if (presentation = Presentation.find(presentationId)) {
        return Factory.open(presentation, +slideNumber);
      }
    };

    Router.prototype["new"] = function() {
      return this.navigate((new Presentation).url(), true);
    };

    return Router;

  })(Backbone.Router);

  $(function() {
    Factory.Editor = new Editor({
      el: $('.writing textarea')
    });
    Factory.SlideViewer = new SlideViewer({
      el: $('.slide-container')
    });
    Factory.SlidesBrowser = new SlidesBrowser({
      el: $('.authoring .slides')
    });
    Factory.MainMenu = new MainMenu({
      el: $('.authoring menu')
    });
    Factory.Browser = new PresentationsBrowser({
      el: $('.presentations-browser')
    });
    Factory.Settings = new Settings;
    Factory.Router = new Router;
    window.socket = new eio.Socket({
      host: location.host
    });
    Factory.Server.listen(socket);
    Factory.Settings.fetch();
    catchLinkClicks();
    return Backbone.history.start({
      pushState: true
    });
  });

}).call(this);
