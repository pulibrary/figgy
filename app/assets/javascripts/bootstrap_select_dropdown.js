$(function (){
    // for some strange reason selectpicker prevents the click-event. so just use mouseup
    // when clicking on an optgroup "label", toggle it's "children"
    $(document).on("mouseup", ".bootstrap-select .dropdown-header", function (){
        var $optgroup = $(this),
            $ul = $optgroup.closest("ul"),
            optgroup = $optgroup.data("optgroup"),

            // options that belong to this optgroup
            $options = $ul.find("[data-optgroup="+optgroup+"]").not(".selected").not($optgroup);

        // show/hide options
        if($optgroup.hasClass("closed")) {
          $options.show();
        } else {
          $options.hide();
        }

        $optgroup.toggleClass("closed");
    });

    // initially close all optgroups that have the class "closed"
    $(document).on("loaded.bs.select", function (){
        $(this).find(".dropdown-header.closed").each(function (){
            var $optgroup = $(this),
                $ul = $optgroup.closest("ul"),
                optgroup = $optgroup.data("optgroup"),

                // options that belong to this optgroup
                $options = $ul.find("[data-optgroup="+optgroup+"]").not(".selected").not($optgroup);

            // show/hide options
            $options.hide();
        });
    });
    $(document).on("changed.bs.select", function(){
      $(this).find(".dropdown-header.closed").each(function(){
        var $optgroup = $(this),
            $ul = $optgroup.closest("ul"),
            optgroup = $optgroup.data("optgroup"),

            // options that belong to this optgroup
            $options = $ul.find("[data-optgroup="+optgroup+"]").not(".selected").not($optgroup);

        // show/hide options
        if($optgroup.hasClass("closed")) {
          $options.hide();
        } else {
          $options.show();
        }
      })
    });
});
