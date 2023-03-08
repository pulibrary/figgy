<template>
  <div id="folder-preview">
    <div class="info-pane" />
    <div class="details">
      <ul>
        <li
          v-for="child in folder.children"
          :key="child.path"
        >
          <div
            v-if="child.expandable"
            class="icon"
          >
            <svg><path d="M11 5h13v17h-24v-20h8l3 3zm-10-2v18h22v-15h-12.414l-3-3h-6.586z" /></svg>
          </div>
          <lux-icon-base
            v-else
            class="icon"
            width="25"
            height="25"
            icon-name="file"
          >
            <lux-icon-file />
          </lux-icon-base>
          <span class="label">
            {{ child.label }}
          </span>
        </li>
      </ul>
    </div>
    <div class="actions">
      <hyperlink
        href="#"
        variation="button solid"
      >
        Ingest {{ folder.label }} directory
      </hyperlink>
    </div>
  </div>
</template>
<script>
// Support choosing a single directory for use in Bulk Ingest.
// TODO: Add multi-select functionality for file select.
export default {
  name: 'FolderPreview',
  props: {
    folder: {
      type: Object,
      default: null
    }
  },
  data () {
    return {}
  },
  computed: {
  },
  methods: {
  }
}
</script>
<style scope>
  #folder-preview {
    width: 100%;
    height: 100%;
  }
  #folder-preview > .info-pane {
    height: 60px;
    padding: 10px;
  }
  #folder-preview > .details {
    height: calc(100% - 120px);
    overflow-y: scroll;
    padding: 10px;
  }
  #folder-preview > .actions {
    height: 60px;
    padding: 10px;
    display: flex;
    align-items: center;
  }
  #folder-preview .icon {
    display: inline-block;
    margin-left: 0;
  }
  #folder-preview .lux-icon {
    margin-left: 0;
  }
  #folder-preview .icon svg {
    width: 25px;
    height: 25px;
  }
  #folder-preview .label {
    display: inline-block;
  }
  #folder-preview li {
    width: 100%;
    padding-bottom: 5px;
    border-bottom: 1px solid gray;
  }

  #folder-preview ul {
    list-style-type: none;
    padding: 0;
    padding-left: 0px;
  }
</style>
