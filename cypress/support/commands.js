// Custom commands for authentication testing

// Command to register a new user
Cypress.Commands.add('registerUser', (email, password) => {
  cy.visit('/registration/new')
  cy.get('input[name="user[email]"]').type(email)
  cy.get('input[name="user[password]"]').type(password)
  cy.get('input[name="user[password_confirmation]"]').type(password)
  cy.get('input[type="submit"]').click()
})

// Command to login an existing user
Cypress.Commands.add('loginUser', (email, password) => {
  cy.visit('/session/new')
  cy.get('input[name="email"]').type(email)
  cy.get('input[name="password"]').type(password)
  cy.get('input[type="submit"]').click()
})

// Command to clear user data (for test cleanup)
Cypress.Commands.add('clearUserData', () => {
  cy.request({
    method: 'DELETE',
    url: '/cypress_test_helpers/clear_users',
    failOnStatusCode: false
  })
})

// Command to seed test user
Cypress.Commands.add('seedTestUser', (email = 'test@example.com', password = 'password123') => {
  cy.request({
    method: 'POST',
    url: '/cypress_test_helpers/create_user',
    body: {
      email: email,
      password: password
    },
    failOnStatusCode: false
  })
})