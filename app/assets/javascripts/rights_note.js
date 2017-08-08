/* toggle rights note field based on which rights statement is selected */
$(document).ready(function(){
    $('select.rights-statement').change(rights_note_visibility);
});

function rights_note_visibility() {
    var stmt = $('select.rights-statement');
    var note = $('.rights-note');
    if ( $.inArray(stmt.val(), stmt.data("notable"))  == -1) {
        note.val('');
        note.attr('readonly', 1);
    } else {
        note.val( note.data('original-value') );
        note.removeAttr('readonly');
    }
}
