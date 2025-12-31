import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]
  static values = {
    redirectUrl: String
  }

  connect() {
    // Check if WebAuthn is supported
    if (!window.PublicKeyCredential) {
      this.showError("WebAuthn is not supported in this browser")
      return
    }
  }

  async enableTwoFactor() {
    try {
      this.showStatus("Preparing security key registration...")
      
      // Get registration options from server
      const optionsResponse = await fetch('/webauthn_credentials/new')
      if (!optionsResponse.ok) {
        throw new Error('Failed to get registration options')
      }
      
      const options = await optionsResponse.json()
      
      // Handle the challenge and user ID based on their actual format
      try {
        // Challenge is already an ArrayBuffer, no conversion needed
        if (typeof options.challenge === 'string') {
          options.challenge = this.base64urlToArrayBuffer(options.challenge)
        }
        
        // User ID needs to be converted from string to ArrayBuffer
        if (typeof options.user.id === 'string') {
          options.user.id = this.stringToArrayBuffer(options.user.id)
        }
      } catch (error) {
        console.error('Error converting WebAuthn options:', error)
        console.log('Options received:', options)
        throw new Error('Failed to process WebAuthn options from server')
      }
      
      this.showStatus("Please use your fingerprint reader or security key...")
      
      // Create the credential
      const credential = await navigator.credentials.create({ publicKey: options })
      
      this.showStatus("Registering security key...")
      
      // Send credential to server
      const registerResponse = await fetch('/webauthn_credentials', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({
          id: credential.id,
          rawId: this.arrayBufferToBase64url(credential.rawId),
          type: credential.type,
          response: {
            clientDataJSON: this.arrayBufferToBase64url(credential.response.clientDataJSON),
            attestationObject: this.arrayBufferToBase64url(credential.response.attestationObject)
          }
        })
      })
      
      const result = await registerResponse.json()
      
      if (result.status === 'success') {
        this.showSuccess(result.message)
        // Reload page to show updated 2FA status
        setTimeout(() => window.location.reload(), 1500)
      } else {
        this.showError(result.message)
      }
      
    } catch (error) {
      console.error('WebAuthn registration error:', error)
      if (error.name === 'NotAllowedError') {
        this.showError('Security key registration was cancelled or timed out')
      } else if (error.name === 'InvalidStateError') {
        this.showError('This security key is already registered')
      } else {
        this.showError('Failed to register security key: ' + error.message)
      }
    }
  }

  async addCredential() {
    try {
      const nickname = prompt('Enter a name for this security key:')
      if (!nickname) return
      
      this.showStatus("Preparing security key registration...")
      
      // Get registration options from server
      const optionsResponse = await fetch('/webauthn_credentials/new')
      if (!optionsResponse.ok) {
        throw new Error('Failed to get registration options')
      }
      
      const options = await optionsResponse.json()
      
      // Convert base64url to ArrayBuffer for the challenge and user ID
      options.challenge = this.base64urlToArrayBuffer(options.challenge)
      options.user.id = this.base64urlToArrayBuffer(options.user.id)
      
      this.showStatus("Please use your fingerprint reader or security key...")
      
      // Create the credential
      const credential = await navigator.credentials.create({ publicKey: options })
      
      this.showStatus("Registering security key...")
      
      // Send credential to server
      const registerResponse = await fetch('/webauthn_credentials', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({
          id: credential.id,
          rawId: this.arrayBufferToBase64url(credential.rawId),
          type: credential.type,
          nickname: nickname,
          response: {
            clientDataJSON: this.arrayBufferToBase64url(credential.response.clientDataJSON),
            attestationObject: this.arrayBufferToBase64url(credential.response.attestationObject)
          }
        })
      })
      
      const result = await registerResponse.json()
      
      if (result.status === 'success') {
        this.showSuccess(result.message)
        // Reload page to show new credential
        setTimeout(() => window.location.reload(), 1500)
      } else {
        this.showError(result.message)
      }
      
    } catch (error) {
      console.error('WebAuthn registration error:', error)
      if (error.name === 'NotAllowedError') {
        this.showError('Security key registration was cancelled or timed out')
      } else if (error.name === 'InvalidStateError') {
        this.showError('This security key is already registered')
      } else {
        this.showError('Failed to register security key: ' + error.message)
      }
    }
  }

  async authenticate() {
    try {
      this.showStatus("Preparing authentication...")
      
      // Get authentication options from server
      const optionsResponse = await fetch('/webauthn_credentials/auth_options')
      if (!optionsResponse.ok) {
        throw new Error('Failed to get authentication options')
      }
      
      const options = await optionsResponse.json()
      
      // Handle the challenge and credential IDs based on their actual format
      try {
        // Challenge might already be an ArrayBuffer
        if (typeof options.challenge === 'string') {
          options.challenge = this.base64urlToArrayBuffer(options.challenge)
        }
        
        // Convert credential IDs if they exist
        if (options.allowCredentials && options.allowCredentials.length > 0) {
          options.allowCredentials = options.allowCredentials.map(cred => ({
            ...cred,
            id: typeof cred.id === 'string' ? this.base64urlToArrayBuffer(cred.id) : cred.id
          }))
        }
      } catch (error) {
        console.error('Error converting authentication options:', error)
        console.log('Authentication options received:', options)
        throw new Error('Failed to process authentication options from server')
      }
      
      this.showStatus("Please use your fingerprint reader or security key...")
      
      // Get the credential
      const assertion = await navigator.credentials.get({ publicKey: options })
      
      this.showStatus("Verifying...")
      
      // Send assertion to server
      const verifyResponse = await fetch('/webauthn_credentials/verify', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({
          id: assertion.id,
          rawId: this.arrayBufferToBase64url(assertion.rawId),
          type: assertion.type,
          response: {
            clientDataJSON: this.arrayBufferToBase64url(assertion.response.clientDataJSON),
            authenticatorData: this.arrayBufferToBase64url(assertion.response.authenticatorData),
            signature: this.arrayBufferToBase64url(assertion.response.signature),
            userHandle: assertion.response.userHandle ? this.arrayBufferToBase64url(assertion.response.userHandle) : null
          }
        })
      })
      
      const result = await verifyResponse.json()
      
      if (result.status === 'success') {
        this.showSuccess(result.message)
        return true
      } else {
        this.showError(result.message)
        return false
      }
      
    } catch (error) {
      console.error('WebAuthn authentication error:', error)
      if (error.name === 'NotAllowedError') {
        this.showError('Authentication was cancelled or timed out')
      } else {
        this.showError('Authentication failed: ' + error.message)
      }
      return false
    }
  }

  async authenticateAndContinue() {
    const success = await this.authenticate()
    if (success) {
      // Dispatch success event for the 2FA page to handle
      this.dispatch('success', { detail: { message: 'Authentication successful' } })
      
      // Redirect if URL is provided
      if (this.hasRedirectUrlValue && this.redirectUrlValue) {
        window.location.href = this.redirectUrlValue
      }
    }
  }

  // Utility methods for base64url conversion
  base64urlToArrayBuffer(base64url) {
    if (!base64url) {
      throw new Error('base64url string is empty or undefined')
    }
    
    // Convert base64url to base64
    let base64 = base64url.replace(/-/g, '+').replace(/_/g, '/')
    
    // Add padding if needed
    while (base64.length % 4) {
      base64 += '='
    }
    
    try {
      const binary = atob(base64)
      const buffer = new ArrayBuffer(binary.length)
      const bytes = new Uint8Array(buffer)
      for (let i = 0; i < binary.length; i++) {
        bytes[i] = binary.charCodeAt(i)
      }
      return buffer
    } catch (error) {
      console.error('Failed to decode base64url string:', base64url)
      throw new Error(`Invalid base64url string: ${error.message}`)
    }
  }

  arrayBufferToBase64url(buffer) {
    const bytes = new Uint8Array(buffer)
    let binary = ''
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i])
    }
    return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
  }

  stringToArrayBuffer(str) {
    const encoder = new TextEncoder()
    return encoder.encode(str)
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').getAttribute('content')
  }

  showStatus(message) {
    this.showMessage(message, 'blue')
  }

  showSuccess(message) {
    this.showMessage(message, 'green')
  }

  showError(message) {
    this.showMessage(message, 'red')
  }

  showMessage(message, color) {
    // Create or update status message
    let statusEl = document.getElementById('webauthn-status')
    if (!statusEl) {
      statusEl = document.createElement('div')
      statusEl.id = 'webauthn-status'
      statusEl.className = `fixed top-4 right-4 z-50 p-4 rounded-md shadow-lg max-w-sm`
      document.body.appendChild(statusEl)
    }

    const colorClasses = {
      blue: 'bg-blue-50 text-blue-800 border-blue-200',
      green: 'bg-green-50 text-green-800 border-green-200',
      red: 'bg-red-50 text-red-800 border-red-200'
    }

    statusEl.className = `fixed top-4 right-4 z-50 p-4 rounded-md shadow-lg max-w-sm border ${colorClasses[color]}`
    statusEl.textContent = message

    // Auto-hide success and error messages
    if (color !== 'blue') {
      setTimeout(() => {
        if (statusEl.parentNode) {
          statusEl.parentNode.removeChild(statusEl)
        }
      }, 5000)
    }
  }
}
