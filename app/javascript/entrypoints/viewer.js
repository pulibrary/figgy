import UVManager from '@viewer/uv_manager'
import 'leaflet/dist/leaflet.css'
const UVManagerInstance = new UVManager()
window.addEventListener('uvLoaded', UVManagerInstance.initialize.bind(UVManagerInstance), false)
