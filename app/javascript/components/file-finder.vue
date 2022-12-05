<!-- Vue component (.vue) -->
<template>
  <div>
    <Finder :tree="tree" :selectable="true" @select="onSelect" />
    <div>
      <form
        id="file-finder-form"
        novalidate="true"
        >
        <input
            :value={{ text }}
          id="selected-path"
          />
      </form>
    </div>
  </div>
</template>

<script>
import "@jledentu/vue-finder/dist/vue-finder.css";

import { Finder } from '@jledentu/vue-finder'
export default {
  components: {
    Finder
  },
  data () {
    return {
      tree: {
        id: 'root',
        children: [
          {
            id: "fruits",
            label: "Fruits",
            children: [
              {
                id: "fruits/apple1",
                label: "Apple",
                children: [
                  {
                    id: "fruits/apple1/apple2",
                    label: "Apple",
                    children: [
                      {
                        id: "fruits/apple1/apple2/apple3",
                        label: "Apple",
                        children: [
                          {
                            id: "fruits/apple1/apple2/apple3/apple4",
                            label: "Apple"
                          },
                        ]
                      },
                    ]
                  },
                ]
              },
              // ...
            ],
          },
          {
            id: "vegetables",
            label: "Vegetables",
            children: [
              { id: "bean", label: "Beans" },
              // ...
            ],
          },
        ],
      }
    },
    text: ''
  },
  methods: {
    onSelect ({ selected }) {

      console.log(
        `Items with ${selected.join()} IDs are now selected`
      );
    }
  }
}
</script>
