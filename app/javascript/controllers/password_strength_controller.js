import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["password", "confirmation", "indicator", "text", "requirements", "submit"]

  connect() {
    this.updateStrength()
    this.updateSubmitButton()
  }

  updateStrength() {
    const password = this.passwordTarget.value
    const strength = this.calculateStrength(password)
    const requirements = this.checkRequirements(password)
    
    this.updateIndicator(strength)
    this.updateText(strength)
    this.updateRequirements(requirements)
    this.updateSubmitButton()
  }

  updateConfirmation() {
    this.updateSubmitButton()
  }

  calculateStrength(password) {
    if (password.length === 0) return 0
    
    let score = 0
    let multiplier = 1
    
    // Length scoring
    if (password.length >= 6) score += 25
    if (password.length >= 8) score += 15
    if (password.length >= 12) score += 15
    
    // Character diversity
    if (/[a-z]/.test(password)) score += 10
    if (/[A-Z]/.test(password)) score += 10
    if (/[0-9]/.test(password)) score += 10
    if (/[^A-Za-z0-9]/.test(password)) score += 15
    
    // Reduce score for common patterns
    if (/(.)\1{2,}/.test(password)) multiplier -= 0.2 // repeated characters
    if (/123|abc|qwe/i.test(password)) multiplier -= 0.3 // common sequences
    
    return Math.max(0, Math.min(100, score * multiplier))
  }

  checkRequirements(password) {
    return {
      length: password.length >= 6,
      lowercase: /[a-z]/.test(password),
      uppercase: /[A-Z]/.test(password),
      number: /[0-9]/.test(password),
      special: /[^A-Za-z0-9]/.test(password)
    }
  }

  updateIndicator(strength) {
    const indicator = this.indicatorTarget
    const percentage = strength
    
    // Update width
    indicator.style.width = `${percentage}%`
    
    // Update color based on strength
    indicator.classList.remove('bg-red-500', 'bg-yellow-500', 'bg-blue-500', 'bg-green-500')
    
    if (percentage < 25) {
      indicator.classList.add('bg-red-500')
    } else if (percentage < 50) {
      indicator.classList.add('bg-yellow-500')
    } else if (percentage < 75) {
      indicator.classList.add('bg-blue-500')
    } else {
      indicator.classList.add('bg-green-500')
    }
  }

  updateText(strength) {
    const textTarget = this.textTarget
    
    if (strength === 0) {
      textTarget.textContent = ''
      textTarget.className = 'text-sm mt-1'
    } else if (strength < 25) {
      textTarget.textContent = 'Very weak'
      textTarget.className = 'text-sm mt-1 text-red-600'
    } else if (strength < 50) {
      textTarget.textContent = 'Weak'
      textTarget.className = 'text-sm mt-1 text-yellow-600'
    } else if (strength < 75) {
      textTarget.textContent = 'Good'
      textTarget.className = 'text-sm mt-1 text-blue-600'
    } else {
      textTarget.textContent = 'Strong'
      textTarget.className = 'text-sm mt-1 text-green-600'
    }
  }

  updateRequirements(requirements) {
    if (!this.hasRequirementsTarget) return
    
    const requirementsContainer = this.requirementsTarget
    const items = requirementsContainer.querySelectorAll('[data-requirement]')
    
    items.forEach(item => {
      const requirement = item.dataset.requirement
      const met = requirements[requirement]
      const icon = item.querySelector('.requirement-icon')
      const text = item.querySelector('.requirement-text')
      
      if (met) {
        icon.textContent = '✓'
        icon.className = 'requirement-icon text-green-600'
        text.className = 'requirement-text text-green-600'
      } else {
        icon.textContent = '○'
        icon.className = 'requirement-icon text-gray-400'
        text.className = 'requirement-text text-gray-600'
      }
    })
  }

  updateSubmitButton() {
    if (!this.hasSubmitTarget) return

    const password = this.passwordTarget.value
    const confirmation = this.hasConfirmationTarget ? this.confirmationTarget.value : ''
    const strength = this.calculateStrength(password)
    
    // Check if password is strong enough (at least 50% strength)
    const isPasswordStrong = strength >= 50
    
    // Check if passwords match
    const passwordsMatch = password === confirmation && password.length > 0
    
    // Check if password meets minimum requirements
    const requirements = this.checkRequirements(password)
    const meetsMinimumReqs = requirements.length
    
    const shouldEnable = isPasswordStrong && passwordsMatch && meetsMinimumReqs
    
    this.submitTarget.disabled = !shouldEnable
    
    if (shouldEnable) {
      this.submitTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      this.submitTarget.classList.add('hover:bg-blue-700')
    } else {
      this.submitTarget.classList.add('opacity-50', 'cursor-not-allowed')
      this.submitTarget.classList.remove('hover:bg-blue-700')
    }
  }
}