Hull.define({
  type: 'Hull',

  templates: [
    'steps'
  ],

  datasources:{
    steps: function(){
      return $.getJSON(this.options.steps);
    }
  },
  actions:{
    next:'next',
    prev:'prev',
    fix:'fix',
    reset:'reset'
  },

  initialize: function() {
    this.step=0;
  },

  beforeRender: function(data) {
    this.steps = data.steps;
    data.current = data.steps[this.step];
    data.step = this.step+1;
    data.total = data.steps.length;
    return data;
  },

  next: function(e, data){
    this.step++;
    this.step = Math.min(this.step,this.steps.length-1);
    this.postAction(e,'hull.steps.next');
  },
  prev: function(e, data){
    this.step--;
    this.step = Math.max(0,this.step);
    this.postAction(e,'hull.steps.prev', eventData);
  },
  fix: function(e, data){
    eventData = {
      html:this.current.html_fixed,
      js: this.current.js_fixed,
      step: this.step
    };
    this.sandbox.emit('hull.steps.fix',eventData);
  },
  reset: function(e, data){
    eventData = {
      html:this.current.html,
      js: this.current.js,
      step: this.step
    };
    this.sandbox.emit('hull.steps.reset',eventData);
  },
  postAction: function(e,event){
    e.preventDefault();
    this.render();
    this.current = this.steps[this.step]
    eventData = {
      html:this.current.html,
      js: this.current.js,
      step: this.step
    };
    this.sandbox.emit(event,eventData);
  }
});
