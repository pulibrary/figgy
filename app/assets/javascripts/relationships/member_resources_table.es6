import RelatedResourcesTable from 'relationships/related_resources_table';

/**
* Provides functionality to add and remove child works.
*/
export default class MemberResourcesTable extends RelatedResourcesTable {

  constructor(element, form) {
    super(element, form);
    this.attribute = 'member_ids';
  }
}
