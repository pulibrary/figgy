import MemberResourcesTable from '../../../assets/javascripts/relationships/member_resources_table'
const jQ = jest.requireActual("jquery");
global.$ = jQ;

describe('MemberResourcesTable', () => {

  describe('bindAddButton', () => {
    it('binds an event that sends the right ajax call', async () => {
      const resourceId = "7709d87f-0a21-4f8d-b17f-78d5caf4803a"
      const newMemberId = "317fa019-3c12-4423-bfe8-b913111559ed"
      const initialHTML = `
        <div class="panel-body member-resources">
          <table id="members-scanned-resources"
          data-update-url="http://localhost:3000/concern/scanned_resources/${resourceId}"
          data-query-url="/catalog/${resourceId}"
          data-members="[&quot;301a6e54-d934-4bfd-bb5a-10edb5fc1601&quot;]"
          data-param-key="scanned_resource">
          </table>
          <input type="text" name="scanned_resource[member_ids]"
          id="scanned_resource_member_ids" class="related_resource_ids">
          <button name="button" type="submit" class="btn-add-row">Attach</button>
        </div>`
      document.body.innerHTML = initialHTML

      const form = null
      const element = document.getElementsByClassName('member-resources')[0];
      const table = new MemberResourcesTable(element, form)

      // mock $.ajax
      const status = 200
      const data = { status: status }
      const jqxhr = { getResponseHeader: () => null }
      const ajax_spy = jest.spyOn($, 'ajax').mockImplementation(() => { return jQ.Deferred().resolve(data, status, jqxhr) } )

      document.getElementById('scanned_resource_member_ids').value = newMemberId
      document.getElementsByClassName('btn-add-row')[0].click()

      expect(ajax_spy).toBeCalledWith(
        expect.objectContaining({
          url: `http://localhost:3000/concern/scanned_resources/${newMemberId}`,
          data: `{\"scanned_resource\":{\"append_id\":\"${resourceId}\"}}`
        })
      )
    })
  })

  describe('bindRemoveButton', () => {
    it('binds an event that sends the right ajax call', async () => {
      const resourceId = "7709d87f-0a21-4f8d-b17f-78d5caf4803a"
      const oldMemberId = "317fa019-3c12-4423-bfe8-b913111559ed"
      const initialHTML = `
        <div class="panel-body member-resources">
          <table id="members-scanned-resources"
          data-update-url="http://localhost:3000/concern/scanned_resources/${resourceId}"
          data-query-url="/catalog/${resourceId}"
          data-members="[&quot;${oldMemberId}&quot;]"
          data-param-key="scanned_resource">
            <tbody>
              <tr data-resource-id="${oldMemberId}">
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
      const element = document.getElementsByClassName('member-resources')[0];
      const table = new MemberResourcesTable(element, form)

      // mock $.ajax
      const status = 200
      const data = { status: status }
      const jqxhr = { getResponseHeader: () => null }
      const ajax_spy = jest.spyOn($, 'ajax').mockImplementation(() => { return jQ.Deferred().resolve(data, status, jqxhr) } )

      document.getElementsByClassName('btn-remove-row')[0].click()

      expect(ajax_spy).toBeCalledWith(
        expect.objectContaining({
          url: `http://localhost:3000/concern/scanned_resources/${resourceId}`,
          data: `{\"scanned_resource\":{\"member_ids\":[]}}`
        })
      )
    })
  })
});
