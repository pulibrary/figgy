<template>
  <div id="health-status">
    <div v-if="report.status.label">
      <a href="#" data-toggle="modal" data-target="#healthModal">
        <lux-icon-base :icon-color="report.status.icon_color">
          <component :is="`lux-icon-${report.status.icon}`"></component>
        </lux-icon-base>
        Health Status: {{ report.status.label }}
      </a>
    </div>
    <div v-else>
      <img src="@/images/health-report-graphic.svg" width=40 height=40>
        Health Status: Loading...
    </div>

    <div class="modal" tabindex="-1" role="dialog" id="healthModal">
      <div class="modal-dialog" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              <img src="@/images/health-report-graphic.svg" width=50 height=50>
               Resource Health Report</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>

          <div class="modal-body">
            <div v-for="check in report.checks" class="check">
              <lux-icon-base width="50" height="50" :icon-color="check.icon_color">
                <component :is="`lux-icon-${check.icon}`"></component>
              </lux-icon-base>
              <div class="check-status">
                <h6>{{ check.type }} Status: {{ check.label }}</h6>
                <small>{{ check.summary }}</small>
                <div v-if="check.display_unhealthy_resources"
                     class="problematic-resources-accordion accordion"
                     id="`problematic-resources-accordion-%{check.name}-files`">
                  <span class="problematic-resources-arrow-right">
                    <lux-icon-base width="20" height="20" :icon-color="check.icon_color">
                      <lux-icon-arrow-right></lux-icon-arrow-right>
                    </lux-icon-base>
                  </span>
                  <span class="problematic-resources-arrow-down">
                    <lux-icon-base width="20" height="20" :icon-color="check.icon_color">
                      <lux-icon-arrow-down></lux-icon-arrow-down>
                    </lux-icon-base>
                  </span>
                  <button class="btn btn-link text-left collapsed" type="button"
                    data-toggle="collapse"
                    :data-target="`#problematic-resources-collapse-${check.name}`"
                    aria-expanded="true"
                    aria-controls="collapseOne">
                    Show Problematic Resources
                  </button>
                  <div

                      class="problematic-resources collapse"
                      loaded="true"
                      :id="`#problematic-resources-collapse-${check.name}`"
                      aria-labelledby="headingOne"
                      data-parent="`problematic-resources-accordion-%{check.name}-files`">
                    <div class="problematic-resources-list"
                         :id="`problematic-resources-list-%{check.name}`">
                      <ul>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'HealthReport',
  props: {
    loadPath: {
      type: String,
      required: true,
    }
  },
  data () {
    return {
      report: {
        status: {
          label: null
        },
        checks: []
      }
    }
  },
  mounted() {
    this.loadReport()
  },
  methods: {
    async loadReport() {
      // TODO: remove this sleep, it's just for checking that data fills in as
      // desired
      await new Promise(r => setTimeout(r, 2000));
      let report = await fetch(
        this.loadPath,
        { credentials: 'include' }
      )
        .then((response) => response.json())
      console.log(report)
      this.report = report
    }
  }
}
</script>

<style scope>
</style>
