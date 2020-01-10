<template>
  <div>
    <input
      name="numismatics_issue[numismatic_monogram_ids][]"
      type="hidden"
      :value="id"
    >

    <form
      :action="action"
      :method="method"
      @submit.prevent="submit($event)"
      @created="created"
      accept-charset="UTF-8"
      enctype="application/json"
      id="nested_new_numismatics_monogram"
      class="simple_form new_numismatics_monogram"
      >

      <input
        name="utf8"
        type="hidden"
        value="✓" />

      <div id="metadata" class="form-panel-content">
        <div class="panel-body">
          <div class="form-group string required numismatics_monogram_title">
            <label
              for="numismatics_monogram_title"
              class="control-label string required"
              >
              <span class="label label-info required-tag">required</span> Title
            </label>

            <input
              name="numismatics_issue[numismatic_monogram_ids][]"
              type="hidden"
              :value="id"
            />

            <input
              aria-required="true"
              type="text"
              name="numismatics_monogram[title]"
              id="numismatics_monogram_title"
              class="form-control string required form-control"
              v-model="title"
            />
          </div>
        </div>

        <div class="panel-save-controls">
          <input
            type="submit"
            name="commit"
            value="Save"
            class="btn btn-primary save"
            :disabled="disabled"
          />
        </div>
      </div>
    </form>
  </div>
</template>
<script>
import axios from 'axios'

export default {
  name: 'IssueMonogramForm',
  props: {
    action: {
      type: String,
      default: '/concern/numismatics/monograms.json'
    },
    method: {
      type: String,
      default: 'post'
    }
  },
  data: function () {
    return {
      id: null,
      title: null,
      requesting: false
    }
  },
  computed: {
    valid: function () {
      return this.title !== null && this.title.length > 0
    },
    disabled: function () {
      return this.requesting || !this.valid
    }
  },
  methods: {
    created: function (response) {
      const data = response.data
      const idModel = data.id
      this.id = idModel.id
    },
    reset: function () {
      this.id = null
      this.title = null
    },
    submit: function (event) {
      const title = event.target.elements.numismatics_monogram_title.value
      const formData = {
        'numismatics_monogram': { title }
      }

      this.requesting = true
      axios.post(this.action, formData).then(response => {
        this.requesting = false
        // this.$emit('attach-monogram', response)
        // The Object with "detail" is required for the CustomEvent API
        const event = new CustomEvent('attach-monogram', { detail: response })
        window.dispatchEvent(event)

        this.created(response)
        this.reset()
      })
    }
  }
}
</script>
