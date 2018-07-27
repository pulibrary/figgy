
/**
 * Class for detecting duplicate resources given an <input> element
 *
 */
class DuplicateResourceDetector {
  constructor($element, messenger) {
    this.$element = $element
    this.messenger = messenger;
    this.$element.data('_object', this)
    this.field = this.$element.data('field')
    this.existing = this.$element.data('value')
    this.$element.change(this.onchange)
  }

  setQueryUrl() {
    this.value = this.$element.val()
    this.queryUrl = `/catalog?f[${this.field}][]=${this.value}`
    if(this.existing)
      this.queryUrl += `&q=NOT+id:${this.existing}`
  }

  appendWarning() {
    this.$warning = $(`<div class="duplicates alert alert-warning">${this.messenger.call(this, this.queryUrl)}</div>`)
      .appendTo(this.$element.parent())
  }

  removeWarning() {
    if ( this.$warning ) {
      this.$warning.remove()
      delete this.$warning
    }
  }

  query() {
    $.ajax({ url: `${this.queryUrl}&format=json`, context: this })
      .done(function(data) {
        if ( data.response.docs.length > 0 ) {
          this.appendWarning()
        } else {
          this.removeWarning()
        }
      }
    )
  }

  onchange() {
    let self = $(this).data('_object')
    if($(this).val()) {
      self.setQueryUrl()
      self.query()
    } else {
      self.removeWarning()
    }
  }
}

/**
 * Factory for building DuplicateResourceDetector instances
 *
 */
export default class DuplicateResourceDetectorFactory {

  /**
   * Messaging callback for generic resource properties
   *
   */
  static propertyMessenger() {
    return `This property is already in use.  Please consider a metadata field to help differentiate between objects with the same metadata.`
  }

  /**
   * Messaging callback for source_metadata_identifier resource properties
   *
   */
  static sourceMetadataIdMessenger(queryUrl) {
    return `This ID is already in use: <a href=${queryUrl}>view records using this Source Metadata ID</a>.  Please consider using the Portion Note field to help differentiate between objects with the same metadata.`
  }

  /**
   * Messaging callback for barcode resource properties
   *
   */
  static barcodeMessenger(queryUrl) {
    return `This barcode is already in use: <a href=${queryUrl}>view records using this barcode</a>.  Please consider using the Description field to help differentiate between objects with the same metadata.`
  }

  /**
   * Construct the DuplicateResourceDetector instance
   *
   */
  static build($element) {
    let model = $element.data('model')
    let messenger = DuplicateResourceDetectorFactory.propertyMessenger

    switch(model) {
      case 'ScannedResource':
        messenger = DuplicateResourceDetectorFactory.sourceMetadataIdMessenger
        break
      case 'EphemeraBox':
        messenger = DuplicateResourceDetectorFactory.barcodeMessenger
        break
      case 'EphemeraFolder':
        messenger = DuplicateResourceDetectorFactory.barcodeMessenger
        break
    }

    return new DuplicateResourceDetector($element, messenger)
  }
}
