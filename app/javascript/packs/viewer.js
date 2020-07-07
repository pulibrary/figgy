import UVManager from 'viewer/uv_manager'
const UVManagerInstance = new UVManager()
window.addEventListener('uvLoaded', UVManagerInstance.initialize.bind(UVManagerInstance), false)
