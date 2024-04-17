import UVManager from '@/viewer/uv_manager'
import 'leaflet/dist/leaflet.css'
const UVManagerInstance = new UVManager()
let timer = window.setInterval(() => {
  if (window.UV !== undefined) {
    UVManagerInstance.initialize()
    window.clearInterval(timer)
  }
}, 5)
