Hull.define({
  type: 'Hull',

  templates: [
    'playground'
  ],

  initialize: function() {
    this.editors = [];
    this.sandbox.on('hull.playground.editor.register', this.sandbox.util._.bind(function(data) {
      this.editors.push(data.editor);
    }, this));
    
    this.sandbox.on('hull.playground.render', this.sandbox.util._.bind(function(uid) {
      console.log("Render",uid);
      var promises = [];
      
      for (var i = this.editors.length - 1; i >= 0; i--) {
        var promise = this.sandbox.data.deferred();
        promises.push(promise);
      };

      this.sandbox.on('hull.playground.editor.update.'+uid, this.sandbox.util._.bind(function(data){
        promises.pop().resolve(data);
      },this));

      var self=this;
      this.sandbox.data.when.apply(undefined, promises).then(function(data){
        self.sandbox.off('hull.playground.editor.update.'+uid);
        var html="";
        self.sandbox.util._.each(arguments,function(res){
          if(res.type=="html"){
            html+=res.content;
          } else if (res.type=="js"){
            eval(res.content);
          }
        });
        self.sandbox.emit('hull.playground.run', html);
      });
    }, this));
  },

  beforeRender: function(data) {
  },
  afterRender: function(data) {
  },

  updateCode: function(code) {
    this.code = code;
    this.render();
  },

  run: function(){
    this.sandbox.emit('hull.playground.render');
  }
});
