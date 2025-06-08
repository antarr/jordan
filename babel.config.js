module.exports = function(api) {
  api.cache(true)
  
  const presets = [
    ['@babel/preset-env', {
      targets: {
        browsers: ['> 1%', 'last 2 versions']
      }
    }]
  ]
  
  const plugins = []
  
  // Add istanbul plugin for code coverage in test/development environment
  if (process.env.NODE_ENV === 'test' || process.env.RAILS_ENV === 'development') {
    plugins.push(['istanbul', {
      exclude: [
        '**/*.cy.js',
        '**/*.test.js',
        '**/*.spec.js',
        'node_modules/**',
        'cypress/**'
      ]
    }])
  }
  
  return {
    presets,
    plugins
  }
}