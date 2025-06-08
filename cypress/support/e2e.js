// Import commands.js using ES2015 syntax:
import './commands'

// Import code coverage support
import '@cypress/code-coverage/support'

// Alternatively you can use CommonJS syntax:
// require('./commands')

// Hide fetch/XHR requests in command log
Cypress.on('window:before:load', (win) => {
  cy.stub(win.console, 'log').as('consoleLog')
  cy.stub(win.console, 'error').as('consoleError')
})