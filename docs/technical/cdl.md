# Controlled Digital Lending (CDL)

With Controlled Digital Lending we allow digital access to a resource while ensuring that access does not exceed the access that would be permitted to the physical item. To achieve this, an item selected for CDL is sequestered physically, then only a single user can access it digitally at any given time. If two copies of an item are sequestered, then two users can access the digital copy, et cetera.

## Access
In Figgy the CDL access business logic can be found in `app/services/cdl/` but its orchestration ranges through the uv_manager javascript, the viewer controller, and the cdl controller. Of course authorization logic can also be found in `ability.rb`. Bibdata provides access to data needed from Alma.

What follows is a fairly detailed step-through of CDL access logic.

- when figgy javascript goes to load the viewer, it checks the user's permissions for the resource via the graphql endpoint. If the user is unauthenticated, figgy redirects to /viewer/auth.
  - https://github.com/pulibrary/figgy/blob/a0d1777be75cd5a56b72b9029fa4a213b554d408/app/javascript/viewer/uv_manager.js#L24
- the viewer controller's auth action uses the ChargeManager to look for CDL-eligible items
  - https://github.com/pulibrary/figgy/blob/b91f5f867abcfce3b4af176764abc822b27bb26b/app/services/cdl/charge_manager.rb#L22
- by checking the bibdata endpoint
  - https://github.com/pulibrary/figgy/blob/b91f5f867abcfce3b4af176764abc822b27bb26b/app/services/cdl/eligible_item_service.rb#L21
  - https://github.com/pulibrary/bibdata/blob/6aa394f2e4d9589d375e5cc7f072694a981fabc2/app/adapters/alma_adapter/alma_item.rb#L154-L156
- If it finds CDL-eligible items it renders a checkout page https://github.com/pulibrary/figgy/blob/b91f5f867abcfce3b4af176764abc822b27bb26b/app/controllers/viewer_controller.rb#L27-L36
- the checkout page submits to the cdl controller charge action https://github.com/pulibrary/figgy/blob/b91f5f867abcfce3b4af176764abc822b27bb26b/app/views/viewer/cdl_checkout.html.erb#L16 which uses the ChargeManager to create a ChargedItem. The ChargeManager also cleans up expired charges as part of its initialization. Once the charge is created, it redirects back to the viewer controller auth action.
- The auth now finds a charged item and redirects to the viewer itself, which this time loads the universal viewer.
- when the viewer is loaded it sets up a CDL timer and return button
  - https://github.com/pulibrary/figgy/blob/b91f5f867abcfce3b4af176764abc822b27bb26b/app/javascript/viewer/cdl_timer.js#L24-L33

## Ingest
Ingest is generally initiated by an "electronic deliver" request in the catalog.
These requests go through illiad to the access and lending services workflow.

Staff scan the book and name the resulting pdf file with the Alma MMS ID. They place this file in the designated directory directory, mounted on the scanning station machines and figgy application servers. Figgy [checks that directory every hour](https://github.com/pulibrary/figgy/blob/a0d1777be75cd5a56b72b9029fa4a213b554d408/config/schedule.rb#L28) and [ingests anything it finds](https://github.com/pulibrary/figgy/blob/a0d1777be75cd5a56b72b9029fa4a213b554d408/app/services/cdl/automatic_ingester.rb). The depositor is listed as cdl_auto_ingest.

## Statistics
Figgy also records some stats on what kinds of users are accessing CDL items. It
would be nice to have some documentation here on how to view those stats.
