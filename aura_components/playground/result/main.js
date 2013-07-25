Hull.define({
  type: 'Hull',

  templates: [
    'result'
  ],

  actions: {
    run:'run'
  },

  initialize: function() {
    this.code = this.options.code || '';

    this.sandbox.on('hull.playground.run', this.sandbox.util._.bind(this.updateCode, this));
    this.sandbox.on('hull.playground.load', this.sandbox.util._.bind(this.updateCode, this));
  },

  beforeRender: function(data) {
    data.code = this.code;
  },

  updateCode: function(code) {
    this.code = code;
    this.render();
  },

  run: function(){
    var uid = this.sandbox.util._.uniqueId();
    this.sandbox.emit('hull.playground.render',uid);
  }
});
