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
  
  return {
    presets,
    plugins
  }
}