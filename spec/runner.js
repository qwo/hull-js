var should;
define(['chai', 'sinonChai'], function(chai, sinonChai) {

  window.chai         = chai;
  window.expect       = chai.expect;
  window.assert       = chai.assert;
  window.sinonChai    = sinonChai;
  should              = chai.should();
  chai.use(sinonChai);
  
  mocha.setup('bdd');
  
  console = window.console || function() {};
 
  // Don't track
  window.notrack = true;

  var specs = [
    'spec/lib/extensions/templates_spec',
    'spec/client/api_spec',
    'spec/lib/hullbase'
  ];
  require(specs, runMocha);
 
});