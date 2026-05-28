export function parseUrl(raw) {
  if (!raw) return { infoUrl: '', savedRegion: null }
  if (raw.endsWith('/info.json')) return { infoUrl: raw, savedRegion: null }

  const rawComponents = raw.split('/')
  const iiifComponents = rawComponents.slice(-4)
  const infoUrl = `${rawComponents.slice(0, -4).join('/')}/info.json`
  const region = iiifComponents[0].split(',')

  if (region.length === 4) {
    return {
      infoUrl,
      savedRegion: {
        x: parseInt(region[0], 10),
        y: parseInt(region[1], 10),
        w: parseInt(region[2], 10),
        h: parseInt(region[3], 10)
      }
    }
  }
  return { infoUrl, savedRegion: null }
} 
