/**
 * 
 * Dumps Push messages in a console
 *
 * @name Console
 * @example <div data-hull-component="developer/console@hull"></div>
 */
Hull.component({
  type: 'Hull',

  templates: ['console'],

  require:['https://d3dy5gmtp8yhk7.cloudfront.net/2.1/pusher.min.js'],

  datasources: {},

  initialize: function() {
    if(!Hull.config.services.settings.pusher_push){
      return false;
    }
    this.pusher_config = Hull.config.services.settings.pusher_push;
    this.pusher = new Pusher(this.pusher_config.key);
    this.messages = "";
    var channel = this.pusher.subscribe(Hull.app.id);
    var self = this;
    channel.bind_all(function(event, d) {
      console.log('An event was triggered with message: ' + event, d);
      self.messages += "\n---------------------------\n"+event+"\n============================\n"
      self.messages += JSON.stringify(d);
      self.render();
    });
  },
  beforeRender: function(data) {
    // console.log(data)
    data.messages = this.messages;
    return data;
  },

  afterRender: function() {
  }

});
