import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "button", "message"]

  subscribe(event) {
    event.preventDefault()
    
    const email = this.emailTarget.value
    const button = this.buttonTarget
    const originalText = button.textContent
    
    // Update button state
    button.disabled = true
    button.textContent = "Subscribing..."
    
    // Simulate API call (replace with actual implementation)
    setTimeout(() => {
      // Success simulation
      this.messageTarget.innerHTML = `
        <p class="text-green-400">
          Success! We'll notify you at <strong>${email}</strong> when we launch.
        </p>
      `
      
      // Reset form
      this.emailTarget.value = ""
      button.disabled = false
      button.textContent = originalText
      
      // Clear message after 5 seconds
      setTimeout(() => {
        this.messageTarget.innerHTML = ""
      }, 5000)
    }, 1500)
  }
}