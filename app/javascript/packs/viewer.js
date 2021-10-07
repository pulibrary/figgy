import UVManager from 'viewer/uv_manager'
import videojs from 'video.js'
const UVManagerInstance = new UVManager()
window.uv_manager = UVManagerInstance
window.addEventListener('DOMContentLoaded', UVManagerInstance.initialize.bind(UVManagerInstance), false)
