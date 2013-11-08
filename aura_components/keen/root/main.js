/**
 *
 *
 */

Hull.component({

  type: 'Hull',

  require:["//dc8na2hxrj29i.cloudfront.net/code/keen-2.1.0-min.js"],

  templates: ['main'],

  initialize: function(){
    window.Keen.configure(Hull.config.services.settings.keenio_analytics);
  }

});
