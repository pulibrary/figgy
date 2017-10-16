/**
 * Ephemera Project slug generation
 * Generata slug identifier when the client enters or modifies the title for a project
 */

// UUID Generation without Bower, AMD's, or the NPM
function uuidv4() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

/**
 * Class for the slug identifier
 */
function Slug(title, seed, delimiter) {
  this.title = title;
  this.prefix = this.title.toLowerCase().replace(/\s/g, '_');

  this.seed = seed;
  this.delimiter = delimiter;

  // Generate the slug
  this.generate = function generate() {
    return this.prefix + this.delimiter + this.seed.slice(0, 4);
  };
  this.value = this.generate();
};

// Bind to the DOM
(function($, Slug) {
  $(document).ready(function() {
    $('#ephemera_project_title').change(function(e) {
      var slug = new Slug($(this).val(), uuidv4(), '-');
      $('#ephemera_project_slug').val(slug.value);
    });
  });
})(jQuery, Slug, uuidv4);
