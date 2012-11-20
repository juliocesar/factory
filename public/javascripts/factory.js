// Generated by CoffeeScript 1.3.3
(function() {
  var DEFAULT_SLIDE, Editor, MainMenu, Presentation, Router, SlideViewer, SlidesBrowser,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __slice = [].slice;

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
      return Factory.SlidesBrowser.loadSlides(presentation.get('slides'));
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
      return this.currentPresentation.save({
        'slides': slides
      });
    }
  };

  _.extend(Factory, Backbone.Events);

  DEFAULT_SLIDE = "# Introducing Factory\n\nFactory is an in-browser slide creation and\npublishing tool.\n\nNo server setup required. Slides are served straight from\nyour browser.";

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
        }, 1000);
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
      'click a': 'open',
      'click a button': 'clickDelete'
    };

    SlidesBrowser.prototype.template = _.template("<a href=\"<%= url %>\" class=\"icon-star\">\n  <%= summary %>\n  <button class=\"delete icon-trash\"></button>\n</a>");

    SlidesBrowser.prototype.initialize = function() {
      var _this = this;
      return Factory.on('slides:toggle', function(showOrHide) {
        return _this.toggleVisible(showOrHide);
      });
    };

    SlidesBrowser.prototype.open = function(event) {
      var $link;
      if (event.metaKey) {
        return;
      }
      event.preventDefault();
      $link = $(event.target);
      return Factory.Router.navigate($link.attr('href'), true);
    };

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
      console.log("DELETING: " + ($(event.target).parent('a').index()));
      return this.deleteSlide($(event.target).parent('a').index());
    };

    SlidesBrowser.prototype.deleteSlide = function(slideNumber) {
      var presentation, slides;
      presentation = Factory.currentPresentation;
      slides = Factory.currentPresentation.get('slides');
      presentation.set(slides, slides.splice(slideNumber, 1));
      console.log(presentation.get('slides'));
      return Factory.saveCurrentPresentation();
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

    SlidesBrowser.prototype.toggleVisible = function(showOrHide) {
      if (showOrHide === 'show') {
        return this.$el.fadeIn(250);
      } else if ('hide') {
        return this.$el.fadeOut(100);
      }
    };

    SlidesBrowser.prototype.makeSummary = function(markdown) {
      var $placeholder;
      $placeholder = $('<div></div>').html(marked(markdown));
      return $placeholder.find('*:first-child').text();
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
      'click .new-slide': 'createNewSlide'
    };

    MainMenu.prototype.toggleSlides = function() {
      var $button;
      $button = $(event.target);
      if ($button.hasClass('section-visible')) {
        $button.toggleClass('section-visible', false);
        return Factory.trigger('slides:toggle', 'hide');
      } else {
        $button.toggleClass('section-visible', true);
        return Factory.trigger('slides:toggle', 'show');
      }
    };

    MainMenu.prototype.createNewSlide = function() {
      var presentation;
      presentation = Factory.currentPresentation;
      return presentation.addSlide(DEFAULT_SLIDE);
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

    Presentation.prototype.initialize = function() {
      if (this.isNew()) {
        this.set({
          'id': this.makeUniqueId()
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

    Presentation.prototype.sync = function() {
      var attributes, method, model, rest;
      method = arguments[0], model = arguments[1], rest = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      switch (method) {
        case 'create':
        case 'update':
          localStorage.setItem(this.id, JSON.stringify(model));
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
      model.trigger('change');
      return this;
    };

    return Presentation;

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
      return this.navigate('/new', true);
    };

    Router.prototype.open = function(presentationId, slideNumber) {
      var presentation;
      if (slideNumber == null) {
        slideNumber = 0;
      }
      if (presentation = Presentation.find(presentationId)) {
        return Factory.open(presentation, slideNumber);
      }
    };

    Router.prototype["new"] = function() {
      return Factory.open(new Presentation, 0);
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
    Factory.Router = new Router;
    return Backbone.history.start({
      pushState: true
    });
  });

}).call(this);
