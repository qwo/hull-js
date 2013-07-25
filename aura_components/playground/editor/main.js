Hull.define({
  type: 'Hull',

  templates: [
    'editor'
  ],

  initialize: function() {
    if (typeof CodeMirror === 'undefined') {
      throw 'Load CodeMirror before using this component.';
    }

    this.sandbox.on('hull.playground.load', this.sandbox.util._.bind(function(code) {
      this.editor.setValue(code);
    }, this));

    this.sandbox.on('hull.steps.*', this.sandbox.util._.bind(function(data) {
      this.editor.setValue(data[this.options.content]);
    }, this));

    this.sandbox.on('hull.playground.render', this.sandbox.util._.bind(function(uid) {
        this.sandbox.emit('hull.playground.editor.update.'+uid,{editor:this, content:this.editor.getValue(), type: this.options.content});
    }, this));

  },

  afterRender: function() {
    var code = this.options.code || '';
    var theme = this.options.theme || 'default';

    this.editor = new CodeMirror(this.$('.hull-playground-editor')[0], {
      mode: 'htmlmixed',
      value: code,
      tabMode: 'indent',
      theme: theme,
      lineNumbers: false
    });

    this.run(code);
    this.sandbox.emit('hull.playground.editor.register',{editor:this, type:this.options.content});
  },

  actions: {
    run: function() {
      this.run(this.editor.getValue());
    }
  },

  run: function(code) {
    this.sandbox.emit('hull.playground.run',code);
  }
});
