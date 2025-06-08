describe('Authentication Flow', () => {
  const testUser = {
    email: 'cypress-test@example.com',
    password: 'SecurePass123!'
  }

  beforeEach(() => {
    // Clear any existing users before each test
    cy.clearUserData()
  })

  after(() => {
    // Clean up after all tests
    cy.clearUserData()
  })

  describe('User Registration', () => {
    it('should successfully register a new user', () => {
      cy.visit('/registration/new')
      
      // Check page elements
      cy.contains('h2', 'Sign Up').should('be.visible')
      cy.get('input[name="user[email]"]').should('be.visible')
      cy.get('input[name="user[password]"]').should('be.visible')
      cy.get('input[name="user[password_confirmation]"]').should('be.visible')
      cy.get('input[type="submit"]').should('contain.value', 'Sign Up')

      // Fill out registration form
      cy.get('input[name="user[email]"]').type(testUser.email)
      cy.get('input[name="user[password]"]').type(testUser.password)
      cy.get('input[name="user[password_confirmation]"]').type(testUser.password)
      
      // Submit form
      cy.get('input[type="submit"]').click()
      
      // Should redirect to dashboard after successful registration
      cy.url().should('include', '/dashboard')
      cy.contains('Welcome to your dashboard').should('be.visible')
      
      // Check navigation shows user email
      cy.contains(testUser.email).should('be.visible')
      cy.contains('Sign Out').should('be.visible')
    })

    it('should show validation errors for invalid registration', () => {
      cy.visit('/registration/new')
      
      // Try to submit with empty fields
      cy.get('input[type="submit"]').click()
      
      // Should stay on registration page due to HTML5 validation
      cy.url().should('include', '/registration/new')
    })

    it('should show error for password mismatch', () => {
      cy.visit('/registration/new')
      
      cy.get('input[name="user[email]"]').type(testUser.email)
      cy.get('input[name="user[password]"]').type(testUser.password)
      cy.get('input[name="user[password_confirmation]"]').type('different-password')
      
      cy.get('input[type="submit"]').click()
      
      // Should show validation error
      cy.contains('error').should('be.visible')
    })

    it('should not allow duplicate email registration', () => {
      // First, create a user
      cy.registerUser(testUser.email, testUser.password)
      
      // Sign out
      cy.contains('Sign Out').click()
      
      // Try to register with same email
      cy.visit('/registration/new')
      cy.get('input[name="user[email]"]').type(testUser.email)
      cy.get('input[name="user[password]"]').type('different-password')
      cy.get('input[name="user[password_confirmation]"]').type('different-password')
      cy.get('input[type="submit"]').click()
      
      // Should show validation error
      cy.contains('error').should('be.visible')
      cy.url().should('include', '/registration')
    })
  })

  describe('User Login', () => {
    beforeEach(() => {
      // Create a test user for login tests
      cy.seedTestUser(testUser.email, testUser.password)
    })

    it('should successfully login with valid credentials', () => {
      cy.visit('/session/new')
      
      // Check page elements
      cy.contains('h2', 'Sign In').should('be.visible')
      cy.get('input[name="email"]').should('be.visible')
      cy.get('input[name="password"]').should('be.visible')
      cy.get('input[type="submit"]').should('contain.value', 'Sign In')
      
      // Login
      cy.loginUser(testUser.email, testUser.password)
      
      // Should redirect to dashboard
      cy.url().should('include', '/dashboard')
      cy.contains('Welcome to your dashboard').should('be.visible')
      
      // Check navigation shows user email
      cy.contains(testUser.email).should('be.visible')
      cy.contains('Sign Out').should('be.visible')
    })

    it('should show error for invalid credentials', () => {
      cy.visit('/session/new')
      
      cy.get('input[name="email"]').type(testUser.email)
      cy.get('input[name="password"]').type('wrong-password')
      cy.get('input[type="submit"]').click()
      
      // Should show error message
      cy.contains('Invalid email or password').should('be.visible')
      cy.url().should('include', '/session')
    })

    it('should show error for non-existent user', () => {
      cy.visit('/session/new')
      
      cy.get('input[name="email"]').type('nonexistent@example.com')
      cy.get('input[name="password"]').type('any-password')
      cy.get('input[type="submit"]').click()
      
      // Should show error message
      cy.contains('Invalid email or password').should('be.visible')
      cy.url().should('include', '/session')
    })
  })

  describe('Dashboard Access Protection', () => {
    it('should redirect unauthenticated users to login', () => {
      cy.visit('/dashboard')
      
      // Should redirect to login page
      cy.url().should('include', '/session/new')
      cy.contains('Please log in to access the dashboard').should('be.visible')
    })

    it('should allow authenticated users to access dashboard', () => {
      // Create and login user
      cy.seedTestUser(testUser.email, testUser.password)
      cy.loginUser(testUser.email, testUser.password)
      
      // Should be on dashboard
      cy.url().should('include', '/dashboard')
      cy.contains('Welcome to your dashboard').should('be.visible')
    })
  })

  describe('User Logout', () => {
    beforeEach(() => {
      // Create and login user for logout tests
      cy.seedTestUser(testUser.email, testUser.password)
      cy.loginUser(testUser.email, testUser.password)
    })

    it('should successfully logout user', () => {
      // Should be on dashboard
      cy.url().should('include', '/dashboard')
      
      // Click logout
      cy.contains('Sign Out').click()
      
      // Should redirect to home page
      cy.url().should('not.include', '/dashboard')
      
      // Try to access dashboard - should redirect to login
      cy.visit('/dashboard')
      cy.url().should('include', '/session/new')
    })
  })

  describe('Navigation Links', () => {
    it('should navigate between registration and login pages', () => {
      cy.visit('/registration/new')
      
      // Click "Sign in" link
      cy.contains('Sign in').click()
      cy.url().should('include', '/session/new')
      cy.contains('h2', 'Sign In').should('be.visible')
      
      // Click "Sign up" link  
      cy.contains('Sign up').click()
      cy.url().should('include', '/registration/new')
      cy.contains('h2', 'Sign Up').should('be.visible')
    })
  })

  describe('Password Manager Support', () => {
    it('should have proper autocomplete attributes for registration', () => {
      cy.visit('/registration/new')
      
      cy.get('input[name="user[email]"]').should('have.attr', 'autocomplete', 'email')
      cy.get('input[name="user[password]"]').should('have.attr', 'autocomplete', 'new-password')
      cy.get('input[name="user[password_confirmation]"]').should('have.attr', 'autocomplete', 'new-password')
    })

    it('should have proper form attributes', () => {
      cy.visit('/registration/new')
      
      cy.get('form').should('have.attr', 'autocomplete', 'on')
    })
  })
})