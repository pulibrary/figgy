import SaveWorkControl from '@figgy/form/save_work_control'
import DuplicateResourceDetectorFactory from '@figgy/form/detect_duplicates'
import StructureManager from '@figgy/structure_manager'
import ModalViewer from '@figgy/modal_viewer'
import DerivativeForm from '@figgy/derivative_form'
import MetadataForm from '@figgy/metadata_form'
import UniversalViewer from '@figgy/universal_viewer'
import FileSetForm from '@figgy/file_set_form'
import SaveAndIngestHandler from '@figgy/save_and_ingest_handler'
import AutoIngestHandler from '@figgy/auto_ingest_handler'
import MemberResourcesTables from '@figgy/relationships/member_resources_table'
import ParentResourcesTables from '@figgy/relationships/parent_resources_table'
import BulkLabeler from '@figgy/bulk_labeler/bulk_label'
import BoundingBoxSelector from '@figgy/bounding_box_selector'
import FieldManager from '@figgy/field_manager'
import Confetti from 'canvas-confetti'

export default class Initializer {
  constructor() {
    this.initialize_form()
    this.initialize_timepicker()
    this.initialize_bbox()
    this.structure_manager = new StructureManager
    this.modal_viewer = new ModalViewer
    this.derivative_form = new DerivativeForm
    this.metadata_form = new MetadataForm
    this.universal_viewer = new UniversalViewer
    this.save_and_ingest_handler = new SaveAndIngestHandler
    this.auto_ingest_handler = new AutoIngestHandler
    this.bulk_labeler = new BulkLabeler
    this.sortable_placeholder()
    this.initialize_multi_fields()
    this.initialize_embargo_date_select()

    // Incompatibility in Blacklight with newer versions of jQuery seem to be
    // causing this to not run. Manually calling it so facet more links work.
    // Blacklight.ajaxModal.setup_modal()
    $("optgroup:not([label=Favorites])").addClass("closed")
    $("select:not(.select2)").selectpicker({'liveSearch': true})

    this.initialize_datatables()
    this.do_confetti()
  }

  initialize_timepicker() {
    $(".timepicker").datetimepicker({
      timeFormat: "HH:mm:ssZ",
      separator: "T",
      dateFormat: "yy-mm-dd",
      timezone: "0",
      showTimezone: false,
      showHour: false,
      showMinute: false,
      showSecond: false,
      hourMax: 0,
      minuteMax: 0,
      secondMax: 0
    })
  }

  // most datatables can be initialized here
  // note that member resources datatables are initialized in that class
  initialize_datatables() {
    $(".datatable").dataTable()
    // Set an initial sort order of data table for coins
    $(".coin-datatable").dataTable({
      "order": [[ 2, "asc" ]]
    })
    // Set an initial sort order of data table for ocr requests
    $("#requests-table").dataTable({
      order: [[1, "desc"]],
    })
  }

  initialize_form() {
    if($("#form-progress").length > 0) {
      new SaveWorkControl($("#form-progress"))
    }

    $(".detect-duplicates").each((_i, element) =>
      DuplicateResourceDetectorFactory.build($(element))
    )

    $("form.edit_file_set.admin_controls").each((_i, element) =>
      new FileSetForm($(element))
    )

    $('select.select2').select2({
      tags: true,
      placeholder: "Nothing selected",
      allowClear: true
    })

    // Allows collapsible optgroups in the subject select
    // Pulled from
    // https://stackoverflow.com/questions/52156973/collapse-expand-optgroup-using-select2
    $("body").on('click', '.select2-container--open .select2-results__group', function() {
      $(this).siblings().toggle();
      let id = $(this).closest('.select2-results__options').attr('id');
      let index = $('.select2-results__group').index(this);
      optgroupState[id][index] = !optgroupState[id][index];
      if(optgroupState[id][index]) {
        $(this).addClass("open")
        $(this).removeClass("closed")
      } else {
        $(this).addClass("closed")
        $(this).removeClass("open")
      }
    })

    let optgroupState = {};

    $('select.select2').on('select2:open', function() {
      $('.select2-dropdown--below').css('opacity', 0);
      setTimeout(() => {
        let groups = $('.select2-container--open .select2-results__group');
        let id = $('.select2-results__options').attr('id');
        if (!optgroupState[id]) {
          optgroupState[id] = {};
        }
        $.each(groups, (index, v) => {
          optgroupState[id][index] = optgroupState[id][index] || false;
          if(optgroupState[id][index]) {
            $(v).siblings().show();
            $(v).addClass("open")
            $(v).removeClass("closed")
          } else {
            $(v).siblings().hide();
            $(v).addClass("closed")
            $(v).removeClass("open")
          }
          optgroupState[id][index] ? $(v).siblings().show() : $(v).siblings().hide();
        })
        $('.select2-dropdown--below').css('opacity', 1);
      }, 0);
    })

    $(".document div.member-resources").each((_i, element) => {
      const $element = $(element)
      const $form = $element.parent('form')
      new MemberResourcesTables($element, $form)
    })

    $(".document div.parent-resources").each((_i, element) => {
      const $element = $(element)
      const $form = $element.parent('form')
      new ParentResourcesTables($element, $form)
    })
  }

  initialize_bbox() {
    $("#bbox").each((_i, element) => {
      const $element = $(element)
      new BoundingBoxSelector($element)
    })
  }

  sortable_placeholder() {
    $( "#sortable" ).on( "sortstart", function( event, ui ) {
      let found_element = $("#sortable").find("li[data-reorder-id]").last()
      ui.placeholder.width(found_element.width())
      ui.placeholder.height(found_element.height())
    })
  }

  initialize_multi_fields() {
    const DEFAULTS = {
      /* callback to run after add is called */
      add:    null,
      /* callback to run after remove is called */
      remove: null,

      controlsHtml:      '<span class=\"input-group-btn field-controls\">',
      fieldWrapperClass: '.field-wrapper',
      warningClass:      '.has-warning',
      listClass:         '.listing',
      inputTypeClass:    '.multi_value',

      addHtml:           '<button type=\"button\" class=\"btn btn-link add\"><span class=\"glyphicon glyphicon-plus\"></span><span class="controls-add-text"></span></button>',
      addText:           'Add another',

      removeHtml:        '<button type=\"button\" class=\"btn btn-link remove\"><span class=\"glyphicon glyphicon-remove\"></span><span class="controls-remove-text"></span> <span class=\"sr-only\"> previous <span class="controls-field-name-text">field</span></span></button>',
      removeText:         'Remove',

      labelControls:      true,
    }

    $.fn.manage_fields = function(option) {
      return this.each(function() {
        var $this = $(this);
        var data  = $this.data('manage_fields');
        var options = $.extend({}, DEFAULTS, $this.data(), typeof option == 'object' && option);

        if (!data) $this.data('manage_fields', (data = new FieldManager(this, options)));
      })
    }
    $('.multi_value.form-group').manage_fields();
  }

  initialize_embargo_date_select() {
    $('#embargo-date-picker').attr('placeholder', 'e.g. ' + new Date().toLocaleDateString());

    $('#embargo_date_action').change(function() {
      const selection = $(this).val();
      if (selection === 'date') {
        $('#embargo-date-picker').show();
      } else {
        $('#embargo-date-picker').hide();
      }
    });
  }

  do_confetti() {
    if ($('*[data-confetti-trigger]').length > 0) {
      var duration = 5 * 1000; // 5 seconds
      var animationEnd = Date.now() + duration;
      var defaults = { startVelocity: 30, spread: 360, ticks: 60, zIndex: 0 };

      function randomInRange(min, max) {
        return Math.random() * (max - min) + min;
      }

      var interval = setInterval(function() {
        var timeLeft = animationEnd - Date.now();

        if (timeLeft <= 0) {
          return clearInterval(interval);
        }

        var particleCount = 50 * (timeLeft / duration);
        // since particles fall down, start a bit higher than random
        Confetti(Object.assign({}, defaults, { particleCount, origin: { x: randomInRange(0.1, 0.3), y: Math.random() - 0.2 } }));
        Confetti(Object.assign({}, defaults, { particleCount, origin: { x: randomInRange(0.7, 0.9), y: Math.random() - 0.2 } }));
      }, 250);
    }
  }
}
