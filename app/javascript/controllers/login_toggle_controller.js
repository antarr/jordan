import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["emailTab", "phoneTab", "emailForm", "phoneForm"]

  connect() {
    // Ensure phone is the default
    this.showPhone()
  }

  showEmail() {
    // Update tab styles
    this.emailTabTarget.className = "flex-1 py-2 px-4 text-sm font-medium rounded-md bg-white text-gray-900 shadow-sm"
    this.phoneTabTarget.className = "flex-1 py-2 px-4 text-sm font-medium rounded-md text-gray-500 hover:text-gray-900"
    
    // Show/hide forms using both inline styles and classes for compatibility
    this.emailFormTarget.style.display = "block"
    this.phoneFormTarget.style.display = "none"
    this.emailFormTarget.classList.remove("hidden")
    this.phoneFormTarget.classList.add("hidden")
    
    // Focus first field in email form
    const emailField = this.emailFormTarget.querySelector('input[type="email"]')
    if (emailField) emailField.focus()
  }

  showPhone() {
    // Update tab styles
    this.phoneTabTarget.className = "flex-1 py-2 px-4 text-sm font-medium rounded-md bg-white text-gray-900 shadow-sm"
    this.emailTabTarget.className = "flex-1 py-2 px-4 text-sm font-medium rounded-md text-gray-500 hover:text-gray-900"
    
    // Show/hide forms using both inline styles and classes for compatibility
    this.phoneFormTarget.style.display = "block"
    this.emailFormTarget.style.display = "none"
    this.phoneFormTarget.classList.remove("hidden")
    this.emailFormTarget.classList.add("hidden")
    
    // Focus first field in phone form
    const phoneField = this.phoneFormTarget.querySelector('input[type="tel"]')
    if (phoneField) phoneField.focus()
  }
}