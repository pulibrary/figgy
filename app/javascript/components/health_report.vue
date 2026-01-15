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
            <template v-for="check in report.checks">
              <health-report-detail :check="check" />
            </template>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import HealthReportDetail from './health_report_detail.vue'
export default {
  name: 'HealthReport',
  components: {
    HealthReportDetail
  },
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
      //await new Promise(r => setTimeout(r, 2000));
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
#health-status {
  flex-grow: 1;
  text-align: right;
  align-self: end;
}
#healthModal {
  img {
    height: 60px;
  }
}

</style>
