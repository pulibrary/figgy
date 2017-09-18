/* ephemera sort title: generate a sort title when the title or language is updated */
var articles = {
  'English': ['a', 'an', 'the'],
  'Portuguese': ['as', 'um', 'uma', 'umas', 'uns'],
  'Spanish': ['el', 'la', 'las', 'los', 'o', 'os']
};

$(document).ready(function(){
    $('input[id="ephemera_folder_title"]').change(sort_title);
    $('select[id="ephemera_folder_language"]').change(sort_title);
});

function sort_title() {
  var sort_title = $('#ephemera_folder_title').val().toLowerCase();
  var lang = $('#ephemera_folder_language').find(':selected').filter(':first').text();
  if (lang in articles) {
    sort_title = sort_title.replace(new RegExp('^(' + articles[lang].join('|') + ')\\s'), '');
  }
  $('#ephemera_folder_sort_title').val(sort_title);
}
