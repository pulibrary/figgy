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
//= require leaflet
//= require Control.Geocoder
//= require leaflet-boundingbox
//
// Required by Blacklight
//= require popper
//= require bootstrap
//= require blacklight/blacklight
//= require cable
//= require form/mutex
//= require jquery-ui/sortable
//= require jquery-ui/draggable
//= require jquery-ui/slider
//= require jquery-ui/datepicker
//= require jquery-ui/selectable
//= require dataTables/jquery.dataTables
//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap
//= require jqueryui-timepicker-addon
//= require nestedSortable/jquery.mjs.nestedSortable
//= require openseadragon/openseadragon
//= require openseadragon/jquery
//= require bootstrap_select_dropdown
//= //require bootstrap/affix
//= require babel/polyfill
//= require hydra-editor/hydra-editor
//= require cocoon
//= require blacklight_range_limit
//= require_tree .
$(document).ready(function() {
  $('.multi_value.form-group').manage_fields();
});
