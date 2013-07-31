/**
 * ## Comments list
 *
 * Allow to list and add comments on an object of the current application.
 *
 * ### Example
 *
 *     <div data-hull-widget="comments@hull" data-hull-id="HULL_OBJECT_ID"></div>
 *
 * or if you want to reference any other Entity (for example the url of the current page)
 *
 *     <div data-hull-widget="comments@hull" data-hull-uid="http://path.to/my/url"></div>
 *
 * ### Option:
 *
 * - `id` or `uid`: Required, The object you want to comment on.
 * - `focus`: Optional, Auto-Focus on the input field. default: false.
 *
 * ### Template:
 *
 * - `comments`: Display a list of comments and a form that allows logged users
 *   to post new comments.
 *
 * ### Datasource:
 *
 * - `comments`: Collection of all the comments made on the object.
 *
 * ### Action:
 *
 * - `comment`: Submits a new comment.
 */

Hull.define({
  type: 'Hull',

  templates: ['comments'],

  actions: {
    comment: 'postComment',
    delete:  'deleteComment',
    flag:    'flagItem'
  },

  options: {
    focus: false
  },

  datasources: {
    comments: ':id/comments'

  },

  beforeRender: function(data){
    "use strict";
    data.comments.each(function(c) {
      c.set('isDeletable', c.get('user').id === data.me.get('id'), {silent: true});
      return c;
    }, this);
    return data;
  },
  afterRender: function() {
    "use strict";
    if(this.options.focus) {
      this.resetForm();
    }
  },

  deleteComment: function(event, data) {
    "use strict";
    event.preventDefault();
    var id = data.data.id;
    this.data.comments.get(id).destroy();
  },

  toggleLoading: function ($el) {
    "use strict";
    var $form = $el.toggleClass('is-loading');
    var $btn = $form.find('.btn');
    $btn.attr('disabled', !$btn.attr('disabled'));
    var $textarea = $form.find('textarea');
    $textarea.attr('disabled', !$textarea.attr('disabled'));
  },

  postComment: function (e) {
    "use strict";
    e.preventDefault();
    var $formWrapper = this.$el.find('.hull-comments__form');
    var $form = $formWrapper.find('form');
    var formData = this.sandbox.dom.getFormData($form);
    var description = formData.description;

    this.toggleLoading($formWrapper);

    if (description && description.length > 0) {
      var attributes = { description: description };
      this.data.comments.create(attributes, {at: 0});
    }
  },

  resetForm: function () {
    "use strict";
    this.$el.find('input,textarea').focus();
  },
  flagItem: function (event, data) {
    "use strict";
    event.preventDefault();
    var id = data.data.id;
    var isCertain = confirm('Do you want to report this content as inappropriate ?');
    if (isCertain) {
      this.sandbox.flag(id);
    }
  }
});
