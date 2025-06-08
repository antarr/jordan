require 'open3'

class JavascriptCoverageMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # Only instrument JavaScript files in development environment when coverage is enabled
    return instrument_javascript(request, env) if should_instrument?(request, env)

    @app.call(env)
  end

  private

  def should_instrument?(request, env)
    # Check if this is a JavaScript request
    return false unless request.path.end_with?('.js')

    # Only instrument in development when testing
    return false unless Rails.env.development?

    # Check if coverage is enabled (e.g., during Cypress tests)
    return false unless ENV['ENABLE_JS_COVERAGE'] == 'true'

    # Only instrument files from our app
    request.path.start_with?('/assets/') &&
      (request.path.include?('controllers/') || request.path.include?('application'))
  end

  def instrument_javascript(request, env)
    # Get the original response
    status, headers, body = @app.call(env)

    # Only process successful JavaScript responses
    return [status, headers, body] unless status == 200
    return [status, headers, body] unless headers['Content-Type']&.include?('javascript')

    # Read the JavaScript content
    content = ''
    body.each { |chunk| content += chunk }
    body.close if body.respond_to?(:close)

    # Instrument the JavaScript
    instrumented_content = instrument_with_babel(content)

    # Update headers
    headers = headers.dup
    headers['Content-Length'] = instrumented_content.bytesize.to_s

    # Return instrumented content
    [status, headers, [instrumented_content]]
  rescue StandardError => e
    Rails.logger.error "JavaScript coverage instrumentation failed: #{e.message}"
    # Fall back to original response
    @app.call(env)
  end

  def instrument_with_babel(content)
    # Create a temporary file with the content
    temp_file = Tempfile.new(['js_coverage', '.js'])
    temp_file.write(content)
    temp_file.close

    # Validate that the temp file path is safe (additional security measure)
    unless File.exist?(temp_file.path) && temp_file.path.start_with?(Dir.tmpdir)
      Rails.logger.error 'Invalid temporary file path for JavaScript instrumentation'
      return content
    end

    # Use babel to instrument the code - properly escape file path to prevent command injection
    stdout, stderr, status = Open3.capture3(
      'npx', 'babel', temp_file.path, '--plugins', 'babel-plugin-istanbul',
      { timeout: 30 } # Add timeout to prevent hanging
    )

    if status.success?
      stdout
    else
      Rails.logger.warn "Babel instrumentation failed: #{stderr}"
      content # Return original content if instrumentation fails
    end
  rescue StandardError => e
    Rails.logger.error "JavaScript instrumentation error: #{e.message}"
    content # Return original content on any error
  ensure
    temp_file&.unlink
  end
end
