/**
 * ## Conversations
 * List all conversations within this app
 *
 * ## Examples
 *
 *     <div data-hull-component="conversations/list@hull"></div>
 *
 * ## Option:
 * - `visibility`: Optional, the visibility level
 * - `mode`: Optional, switch to table view mode if mode === 'expanded'
 * ## Template:
 *
 * - `conversations`: Table of conversations
 *
 * ## Datasource:
 *
 * - `conversations`: List of all conversations
 *
 * ## Action:
 *
 * - `pickConvo`: Select a conversation.
 */

/*global define:true */
(function() {

  function conversationSearchQuery(options) {
    var url = "search/conversations";
    var filter = {
      q: options.search,
      limit: options.limit,
      page: options.page,
      order_by: 'last_message_at DESC',
      boost: (options.boost || 'messages_count')
    };
    return [url, filter];
  }

  function conversationListQuery(options) {
    var url = options.id ? options.id : '';
    url += '/conversations';
    var filter = options.filter || {
      visibility: options.visibility || undefined,
      order_by: 'last_message_at DESC',
      limit: options.limit,
      page: options.page
    };
    return [url, filter];
  }


  Hull.define({
    type: 'Hull',

    templates: ['list', 'table'],

    refreshEvents: ['model.hull.me.change'],

    actions: {
      select: "select",
      search: "search"
    },

    options: {
      limit: 30,
      focus: false
    },

    datasources: {
      conversations: function () {
        var params;
        if (this.options.search && this.options.search.length > 0) {
          args = conversationSearchQuery(this.options);
        } else {
          args = conversationListQuery(this.options);
        }
        return this.api.apply(this, args);
      }
    },

    initialize: function() {
      if (this.options.mode  === 'expanded') {
        this.template = 'table';
      } else {
        this.template = 'list';
      }
      this.sandbox.on('hull.conversation.selected', function(id) {
        if (this.conversations) {
          this.selected = this.conversations[id];
        }
        this.highlight(id);
      }, this);

      this.sandbox.on('hull.conversation.thread.delete', function() {
       this.render();
       this.sandbox.emit('hull.conversation.select', null);
      }, this);
    },

    beforeRender: function(data, errors){
      data.errors = errors;
      var conversations = {};
      if (data.conversations && data.conversations.results) {
        data.conversations = data.conversations.results;
      }
      this.sandbox.util._.map(data.conversations, function(c) {
        conversations[c.id] = c;
      });
      this.conversations = conversations;
      return data;
    },

    highlight: function(id) {
      var selected = this.$el.find('[data-hull-id="'+id+'"]');
      this.$el.find('[data-hull-action="select"]').not(selected).removeClass('selected')
      selected.addClass('selected');
    },

    select: function(e, action) {
      if (action && action.data.id) {
        this.selected = this.conversations[action.data.id];
        this.sandbox.emit('hull.conversation.select', this.selected);
      }
    },

    search: function() {
      this.options.search = this.$find('input[data-hull-search]').val();
      console.warn("Searching for : ", this.options.search);
      this.render();
    }
  });

})();
