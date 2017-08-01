// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3
//= require jquery_ujs
//= require modernizr
//
// Required by Blacklight
//= require blacklight/blacklight
//= require cable
//= require form/mutex
//= require browse_everything
//= require jquery-ui/widgets/sortable
//= require nestedSortable/jquery.mjs.nestedSortable
//= require valhalla/valhalla
//= require_tree .
$(document).ready(function() {
  Initializer = require('figgy_boot')
  window.figgy = new Initializer()
})
