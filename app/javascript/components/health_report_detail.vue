<template>
  <div id="health-report-detail" class="check">
    <lux-icon-base width="50" height="50" :icon-color="check.icon_color">
      <component :is="`lux-icon-${check.icon}`"></component>
    </lux-icon-base>
    <div class="check-status">
      <h6>{{ check.type }} Status: {{ check.label }}</h6>
      <small>{{ check.summary }}</small>

      <div v-if="check.display_unhealthy_resources"
           class="problematic-resources-accordion accordion"
           id="`problematic-resources-accordion-%{check.name}-files`">

        <span>
          <lux-icon-base width="20" height="20" :icon-color="check.icon_color">
            <component :is="`lux-icon-${expandCollapseIcon}`"></component>
          </lux-icon-base>
        </span>

        <button class="btn btn-link text-left" type="button"
            @click="toggleList($event)"
            :aria-expanded="isOpen"
            :aria-controls="`problematic-resources-list-%{check.name}`">
          {{ buttonText }}
        </button>
        <div class="problematic-resources-list"
              v-show="isOpen"
              :id="`problematic-resources-list-%{check.name}`">
          <ul
            >
            <li v-for="resource in check.unhealthy_resources"
                       :key="resource.url">
              <a :href="resource.url" target="_blank">{{ resource.title }}</a>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'HealthReportDetail',
  props: {
    check: {
    }
  },
  data () {
    return {
      isOpen: false
    }
  },
  computed: {
    expandCollapseIcon: function () {
      if (this.isOpen) {
        return 'arrow-down'
      }
      return 'arrow-right'
    },
    buttonText: function () {
      if (this.isOpen) {
        return 'Hide Problematic Resources'
      }
      return 'Show Problematic Resources'
    }
  },
  methods: {
    toggleList: function () {
      this.isOpen = !this.isOpen
    },
  }
}
</script>

<style scope>
.check {
  display: flex;
  margin-bottom: 25px;
  &:last-child {
    margin-bottom: 0;
  }
  .check-status {
    flex-grow: 1;
    text-align: left;
    padding: 10px;
  }
}

.problematic-resources-list {
  ul {
    /* Align problematic resources list with button */
    margin-left: 28px;
  }

  .lux-overlay {
    /* Align problematic resource loading spinner in the center of the button */
    margin-left: 42px;
  }

  .lux-loader {
    /* Set loading spinner color */
    border-left-color: cadetblue !important;
  }
}

.problematic-resources-accordion {
  button {
    margin-bottom: 0.5em;
  }
}
</style>
