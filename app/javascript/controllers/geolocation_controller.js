import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["latitude", "longitude", "locationName", "detectButton", "status"]

  connect() {
    // Check if geolocation is available
    if ("geolocation" in navigator) {
      this.detectButtonTarget.classList.remove("hidden")
    }
  }

  detect() {
    // Show loading state
    this.showStatus("Detecting your location...", "info")
    this.detectButtonTarget.disabled = true
    this.detectButtonTarget.textContent = "Detecting..."

    // Request geolocation
    navigator.geolocation.getCurrentPosition(
      (position) => this.handleSuccess(position),
      (error) => this.handleError(error),
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    )
  }

  async handleSuccess(position) {
    const { latitude, longitude } = position.coords

    // Update form fields
    this.latitudeTarget.value = latitude.toFixed(6)
    this.longitudeTarget.value = longitude.toFixed(6)

    // Try to get location name using reverse geocoding
    try {
      const response = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}`)
      const data = await response.json()
      
      if (data.display_name) {
        // Extract city and state/country from the display name
        const parts = data.display_name.split(',')
        const city = data.address?.city || data.address?.town || data.address?.village || parts[0]
        const state = data.address?.state || data.address?.country || parts[parts.length - 1]
        
        if (city && state) {
          this.locationNameTarget.value = `${city.trim()}, ${state.trim()}`
        }
      }
    } catch (error) {
      console.error("Reverse geocoding failed:", error)
    }

    // Reset button and show success
    this.detectButtonTarget.disabled = false
    this.detectButtonTarget.textContent = "Use My Location"
    this.showStatus("Location detected successfully!", "success")
  }

  handleError(error) {
    let message = "Unable to detect your location"
    
    switch(error.code) {
      case error.PERMISSION_DENIED:
        message = "Location access denied. Please enable location permissions."
        break
      case error.POSITION_UNAVAILABLE:
        message = "Location information is unavailable."
        break
      case error.TIMEOUT:
        message = "Location request timed out. Please try again."
        break
    }

    this.showStatus(message, "error")
    
    // Reset button
    this.detectButtonTarget.disabled = false
    this.detectButtonTarget.textContent = "Use My Location"
  }

  showStatus(message, type) {
    const statusElement = this.statusTarget
    statusElement.textContent = message
    statusElement.classList.remove("hidden", "text-blue-600", "text-green-600", "text-red-600")
    
    switch(type) {
      case "info":
        statusElement.classList.add("text-blue-600")
        break
      case "success":
        statusElement.classList.add("text-green-600")
        break
      case "error":
        statusElement.classList.add("text-red-600")
        break
    }

    // Auto-hide success messages after 5 seconds
    if (type === "success") {
      setTimeout(() => {
        statusElement.classList.add("hidden")
      }, 5000)
    }
  }
}