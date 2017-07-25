/* mutex: only one form element with the class 'mutex' may be used at a time.
   all others will be disabled until it is blank. */
$(document).ready(function(){
    $(".form-group").on("change", ".mutex", mutex)
    $(".mutex[value]").change();
    $(".mutex").attr("required", null)
    $('.multi_value.form-group', this.form).bind('managed_field:remove', function() { 
      $("#mutex_field").val($(".mutex[value]").val());
      $(".mutex").change();
    })
});

function mutex() {
    var $me = $(this);
    var $other = $('.mutex').not($me);
    if ( $me.val() != '' ) {
        $other.attr('disabled', 1);
        $("#mutex_field").val($me.val())
        $("#mutex_field").change()
    } else {
        $other.removeAttr('disabled');
        $("#mutex_field").val($other.val())
        $("#mutex_field").change()
    }
}
