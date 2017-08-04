/* toggle rights note field based on which rights statement is selected */
$(document).ready(function(){
    $('.rights-statement').change(rights_note_visibility);
});

function rights_note_visibility() {
    var stmt = $('.rights-statement');
    var note = $('.rights-note');
    if ( stmt.val() == 'http://rightsstatements.org/vocab/NKC/1.0/' ) {
        note.val('');
        note.attr('readonly', 1);
    } else {
        note.val( note.data('original-value') );
        note.removeAttr('readonly');
    }
}
