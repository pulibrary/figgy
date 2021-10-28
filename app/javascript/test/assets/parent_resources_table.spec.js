import ParentResourcesTable from '../../../assets/javascripts/relationships/parent_resources_table'
const jQ = jest.requireActual("jquery");
global.$ = jQ;

describe('ParentResourcesTable', () => {

  describe('bindAddButton', () => {
    it('binds an event that sends the right ajax call', async () => {
      const resourceId = "7709d87f-0a21-4f8d-b17f-78d5caf4803a"
      const newParentId = "317fa019-3c12-4423-bfe8-b913111559ed"
      const initialHTML = `
        <div class="panel-body parent-resources">
          <table id="parent-raster-resources"
          data-update-url="http://localhost:3000/concern/raster_resources/${resourceId}"
          data-query-url="/catalog/${resourceId}"
          data-parents="[&quot;301a6e54-d934-4bfd-bb5a-10edb5fc1601&quot;]"
          data-param-key="raster_resource">
          </table>
          <input type="text" name="raster_resource[member_ids]"
          id="parent_raster_resource_id_input" class="related_resource_ids">
          <button name="button" id="parent_raster_resource_button" type="submit" class="btn-add-row">Attach</button>
        </div>`
      document.body.innerHTML = initialHTML

      const form = null
      const element = document.getElementsByClassName('parent-resources')[0];
      const table = new ParentResourcesTable(element, form)

      // mock $.ajax
      const status = 200
      const data = { status: status }
      const jqxhr = { getResponseHeader: () => null }
      const ajax_spy = jest.spyOn($, 'ajax').mockImplementation(() => { return jQ.Deferred().resolve(data, status, jqxhr) } )

      document.getElementById('parent_raster_resource_id_input').value = newParentId
      document.getElementById('parent_raster_resource_button').click()

      expect(ajax_spy).toBeCalledWith(
        expect.objectContaining({
          url: `http://localhost:3000/concern/raster_resources/${resourceId}`,
          data: `{\"raster_resource\":{\"append_id\":\"${newParentId}\"}}`
        })
      )
    })
  })

  describe('bindRemoveButton', () => {
    it('binds an event that sends the right ajax call', async () => {
      const resourceId = "7709d87f-0a21-4f8d-b17f-78d5caf4803a"
      const oldParentId = "317fa019-3c12-4423-bfe8-b913111559ed"
      const initialHTML = `
        <div class="panel-body parent-resources">
          <table id="parent-raster-resources"
          data-update-url="http://localhost:3000/concern/raster_resources/${resourceId}"
          data-query-url="/catalog/${resourceId}"
          data-parents="[&quot;${oldParentId}&quot;]"
          data-param-key="raster_resource">

            <tbody>
              <tr data-resource-id="${oldParentId}" data-update-url="/concern/raster_resources/${resourceId}/remove_from_parent">
                <td>
                  <span class="input-group-btn">
                    <button name="button" type="submit" class="btn btn-default btn btn-danger btn-remove-row">Detach</button>
                  </span>
                </td>
              </tr> 
            </tbody>
          </table>
        </div>`
      document.body.innerHTML = initialHTML

      const form = null
      const element = document.getElementsByClassName('parent-resources')[0];
      const table = new ParentResourcesTable(element, form)

      // mock $.ajax
      const status = 200
      const data = { status: status }
      const jqxhr = { getResponseHeader: () => null }
      const ajax_spy = jest.spyOn($, 'ajax').mockImplementation(() => { return jQ.Deferred().resolve(data, status, jqxhr) } )

      document.getElementsByClassName('btn-remove-row')[0].click()

      expect(ajax_spy).toBeCalledWith(
        expect.objectContaining({
          url: `/concern/raster_resources/${resourceId}/remove_from_parent`,
          data: `{\"parent_resource\":{\"id\":\"${oldParentId}\"}}`
        })
      )
    })
  })
});
