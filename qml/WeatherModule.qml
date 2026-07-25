pragma Singleton
import Quickshell
import QtQuick

Singleton {
  id: root

  property real temp: 0
  property real feelsLike: 0
  property int humidity: 0
  property real windSpeed: 0
  property string windDir: ""
  property int uvIndex: 0
  property string condition: ""
  property string weatherCode: ""
  property string iconGlyph: "\ue312"  // weather-cloudy
  property color iconColor: Theme.textSecondary
  property string sunrise: ""
  property string sunset: ""
  property var forecast: []
  property bool loading: false
  property string errorMessage: ""
  property var lastUpdated: new Date()

  function iconForCode(code) {
    const c = parseInt(code)
    if (c === 113) return { glyph: "\ue30d", color: Theme.weatherSun }
    if ([116, 119, 122].includes(c)) return { glyph: "\ue312", color: Theme.textSecondary }
    if ([176, 263, 266, 293, 296, 299, 302, 305, 308, 311, 314, 317, 320, 353, 356, 359].includes(c))
      return { glyph: "\ue318", color: Theme.weatherRain }
    if ([200, 386, 389, 392, 395].includes(c)) return { glyph: "\ue31d", color: Theme.weatherStorm }
    if ([227, 230, 323, 326, 329, 332, 335, 338, 350, 368, 371, 374, 377].includes(c))
      return { glyph: "\ue31a", color: Theme.weatherSnow }
    if ([143, 248, 260].includes(c)) return { glyph: "\ue313", color: Theme.weatherFog }
    return { glyph: "\ue312", color: Theme.textSecondary }
  }

  function refresh() {
    root.loading = true
    root.errorMessage = ""

    const url = "https://wttr.in/" + encodeURIComponent(Config.weatherLocation) + "?format=j1"
    const xhr = new XMLHttpRequest()
    xhr.onreadystatechange = () => {
      if (xhr.readyState !== XMLHttpRequest.DONE) return
      root.loading = false
      if (xhr.status !== 200) {
        root.errorMessage = "Weather fetch failed."
        return
      }
      try {
        const data = JSON.parse(xhr.responseText)
        const current = data.current_condition[0]
        const today = data.weather[0]
        const isMetric = Config.weatherUnits === "metric"

        root.temp = isMetric ? parseFloat(current.temp_C) : parseFloat(current.temp_F)
        root.feelsLike = isMetric ? parseFloat(current.FeelsLikeC) : parseFloat(current.FeelsLikeF)
        root.humidity = parseInt(current.humidity)
        root.windSpeed = isMetric ? parseFloat(current.windspeedKmph) : parseFloat(current.windspeedMiles)
        root.windDir = current.winddir16Point
        root.uvIndex = parseInt(current.uvIndex)
        root.condition = current.weatherDesc[0].value
        root.weatherCode = current.weatherCode

        const iconData = root.iconForCode(current.weatherCode)
        root.iconGlyph = iconData.glyph
        root.iconColor = iconData.color

        root.sunrise = today.astronomy[0].sunrise
        root.sunset = today.astronomy[0].sunset

        root.forecast = data.weather.slice(0, 3).map(day => {
          const dayIcon = root.iconForCode(day.hourly[4].weatherCode)
          return {
            date: day.date,
            maxTemp: isMetric ? parseFloat(day.maxtempC) : parseFloat(day.maxtempF),
            minTemp: isMetric ? parseFloat(day.mintempC) : parseFloat(day.mintempF),
            iconGlyph: dayIcon.glyph,
            iconColor: dayIcon.color
          }
        })

        root.lastUpdated = new Date()
      } catch (e) {
        root.errorMessage = "Weather parse failed"
      }
    }
    xhr.open("GET", url)
    xhr.send()
  }

  Timer {
    interval: Config.weatherRefreshInterval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
