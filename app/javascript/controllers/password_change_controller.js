import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form", "currentPassword", "newPassword", "newPasswordConfirmation"]

  connect() {
    // Add escape key listener to close modal
    this.escapeHandler = this.handleEscape.bind(this)
  }

  disconnect() {
    if (this.escapeHandler) {
      document.removeEventListener('keydown', this.escapeHandler)
    }
  }

  showModal() {
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.classList.add("flex")
    document.body.classList.add("overflow-hidden")
    document.addEventListener('keydown', this.escapeHandler)
    
    // Focus the first input
    this.currentPasswordTarget.focus()
  }

  hideModal() {
    this.modalTarget.classList.add("hidden")
    this.modalTarget.classList.remove("flex")
    document.body.classList.remove("overflow-hidden")
    document.removeEventListener('keydown', this.escapeHandler)
    
    // Reset form
    this.formTarget.reset()
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.hideModal()
    }
  }

  // Close modal when clicking outside
  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) {
      this.hideModal()
    }
  }

  submitForm(event) {
    event.preventDefault()
    
    // Basic client-side validation
    if (!this.validateForm()) {
      return
    }
    
    // Submit the form
    this.formTarget.submit()
  }

  validateForm() {
    const currentPassword = this.currentPasswordTarget.value
    const newPassword = this.newPasswordTarget.value
    const confirmPassword = this.newPasswordConfirmationTarget.value
    
    // Clear previous error states
    this.clearErrors()
    
    let isValid = true
    
    if (!currentPassword) {
      this.showFieldError(this.currentPasswordTarget, "Current password is required")
      isValid = false
    }
    
    if (!newPassword) {
      this.showFieldError(this.newPasswordTarget, "New password is required")
      isValid = false
    } else if (newPassword.length < 8) {
      this.showFieldError(this.newPasswordTarget, "Password must be at least 8 characters")
      isValid = false
    }
    
    if (newPassword !== confirmPassword) {
      this.showFieldError(this.newPasswordConfirmationTarget, "Passwords don't match")
      isValid = false
    }
    
    if (currentPassword && newPassword && currentPassword === newPassword) {
      this.showFieldError(this.newPasswordTarget, "New password must be different from current password")
      isValid = false
    }
    
    return isValid
  }

  showFieldError(field, message) {
    field.classList.add("border-red-500")
    
    // Create or update error message
    let errorElement = field.parentElement.querySelector(".error-message")
    if (!errorElement) {
      errorElement = document.createElement("p")
      errorElement.className = "error-message text-sm text-red-600 mt-1"
      field.parentElement.appendChild(errorElement)
    }
    errorElement.textContent = message
  }

  clearErrors() {
    // Remove error classes and messages
    [this.currentPasswordTarget, this.newPasswordTarget, this.newPasswordConfirmationTarget].forEach(field => {
      field.classList.remove("border-red-500")
      const errorElement = field.parentElement.querySelector(".error-message")
      if (errorElement) {
        errorElement.remove()
      }
    })
  }
}