import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }

  async requestCode(event) {
    event.preventDefault()
    
    const phoneInput = this.element.querySelector('input[name="phone"]')
    const phone = phoneInput ? phoneInput.value : ''
    
    if (!phone) {
      alert('Please enter your phone number first')
      return
    }
    
    try {
      const response = await fetch(this.urlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ phone: phone })
      })
      
      const data = await response.json()
      
      if (response.ok) {
        alert(data.message)
        
        // In development, log the SMS code to console for easy testing
        if (data.development_sms_code) {
          console.log('🔐 Development SMS Code:', data.development_sms_code)
          console.log('📱 You can now use this code to login with your phone number')
        }
      } else {
        alert(data.error)
      }
    } catch (error) {
      alert('Failed to send SMS code')
    }
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').getAttribute('content')
  }
}
