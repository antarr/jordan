require 'json'
require 'simplecov'
require 'fileutils'

class CoverageMerger
  def self.merge_reports(ruby_coverage_path: 'coverage', js_coverage_path: 'coverage-js',
                         output_path: 'coverage-merged')
    new(ruby_coverage_path, js_coverage_path, output_path).merge
  end

  def initialize(ruby_coverage_path, js_coverage_path, output_path)
    @ruby_coverage_path = ruby_coverage_path
    @js_coverage_path = js_coverage_path
    @output_path = output_path
  end

  def merge
    puts 'Merging coverage reports...'

    # Create output directory
    FileUtils.mkdir_p(@output_path)

    # Read Ruby coverage data
    ruby_data = read_ruby_coverage

    # Read JavaScript coverage data
    js_data = read_js_coverage

    # Merge and create combined report
    create_combined_report(ruby_data, js_data)

    puts "Coverage reports merged successfully in #{@output_path}"
  end

  private

  def read_ruby_coverage
    result_set_path = File.join(@ruby_coverage_path, '.resultset.json')
    return {} unless File.exist?(result_set_path)

    JSON.parse(File.read(result_set_path))
  rescue StandardError => e
    puts "Warning: Could not read Ruby coverage data: #{e.message}"
    {}
  end

  def read_js_coverage
    # Read NYC/Istanbul coverage data
    coverage_files = Dir[File.join(@js_coverage_path, 'coverage-final.json')]
    return {} if coverage_files.empty?

    coverage_data = {}
    coverage_files.each do |file|
      data = JSON.parse(File.read(file))
      coverage_data.merge!(data)
    end

    coverage_data
  rescue StandardError => e
    puts "Warning: Could not read JavaScript coverage data: #{e.message}"
    {}
  end

  def create_combined_report(ruby_data, js_data)
    # Calculate totals
    ruby_stats = calculate_ruby_stats(ruby_data)
    js_stats = calculate_js_stats(js_data)

    # Create HTML report
    create_html_report(ruby_stats, js_stats, ruby_data, js_data)

    # Create JSON summary
    create_json_summary(ruby_stats, js_stats)

    # Copy existing reports
    copy_existing_reports
  end

  def calculate_ruby_stats(ruby_data)
    return { lines: 0, covered: 0, percentage: 0, files: 0 } if ruby_data.empty?

    # Extract coverage data from SimpleCov format
    coverage = ruby_data.values.first&.dig('coverage') || {}

    total_lines = 0
    covered_lines = 0
    files = coverage.keys.length

    coverage.each do |file, file_coverage|
      line_coverage = file_coverage['lines'] || []
      line_coverage.each do |hits|
        next if hits.nil?

        total_lines += 1
        covered_lines += 1 if hits.to_i > 0
      end
    end

    percentage = total_lines > 0 ? (covered_lines.to_f / total_lines * 100).round(2) : 0

    {
      lines: total_lines,
      covered: covered_lines,
      percentage: percentage,
      files: files
    }
  end

  def calculate_js_stats(js_data)
    return { lines: 0, covered: 0, percentage: 0, files: 0 } if js_data.empty?

    total_lines = 0
    covered_lines = 0
    files = js_data.keys.length

    js_data.each do |file, coverage|
      statements = coverage['s'] || {}
      statements.each do |line, hits|
        total_lines += 1
        covered_lines += 1 if hits > 0
      end
    end

    percentage = total_lines > 0 ? (covered_lines.to_f / total_lines * 100).round(2) : 0

    {
      lines: total_lines,
      covered: covered_lines,
      percentage: percentage,
      files: files
    }
  end

  def create_html_report(ruby_stats, js_stats, ruby_data, js_data)
    total_lines = ruby_stats[:lines] + js_stats[:lines]
    total_covered = ruby_stats[:covered] + js_stats[:covered]
    total_percentage = total_lines > 0 ? (total_covered.to_f / total_lines * 100).round(2) : 0

    html_content = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Combined Coverage Report</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; }
          .header { background: #f5f5f5; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
          .stats { display: flex; gap: 20px; margin: 20px 0; }
          .stat-box { background: #fff; border: 1px solid #ddd; padding: 15px; border-radius: 5px; min-width: 150px; }
          .percentage { font-size: 24px; font-weight: bold; }
          .good { color: #28a745; }
          .warning { color: #ffc107; }
          .danger { color: #dc3545; }
          table { width: 100%; border-collapse: collapse; margin: 20px 0; }
          th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
          th { background: #f5f5f5; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Combined Coverage Report</h1>
          <p>Generated on #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}</p>
        </div>
      #{'  '}
        <div class="stats">
          <div class="stat-box">
            <h3>Total Coverage</h3>
            <div class="percentage #{coverage_class(total_percentage)}">#{total_percentage}%</div>
            <p>#{total_covered} / #{total_lines} lines covered</p>
          </div>
      #{'    '}
          <div class="stat-box">
            <h3>Ruby Coverage</h3>
            <div class="percentage #{coverage_class(ruby_stats[:percentage])}">#{ruby_stats[:percentage]}%</div>
            <p>#{ruby_stats[:covered]} / #{ruby_stats[:lines]} lines</p>
            <p>#{ruby_stats[:files]} files</p>
          </div>
      #{'    '}
          <div class="stat-box">
            <h3>JavaScript Coverage</h3>
            <div class="percentage #{coverage_class(js_stats[:percentage])}">#{js_stats[:percentage]}%</div>
            <p>#{js_stats[:covered]} / #{js_stats[:lines]} lines</p>
            <p>#{js_stats[:files]} files</p>
          </div>
        </div>
      #{'  '}
        <h2>Coverage by Language</h2>
        <table>
          <thead>
            <tr>
              <th>Language</th>
              <th>Files</th>
              <th>Lines</th>
              <th>Covered</th>
              <th>Percentage</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Ruby</td>
              <td>#{ruby_stats[:files]}</td>
              <td>#{ruby_stats[:lines]}</td>
              <td>#{ruby_stats[:covered]}</td>
              <td class="#{coverage_class(ruby_stats[:percentage])}">#{ruby_stats[:percentage]}%</td>
            </tr>
            <tr>
              <td>JavaScript</td>
              <td>#{js_stats[:files]}</td>
              <td>#{js_stats[:lines]}</td>
              <td>#{js_stats[:covered]}</td>
              <td class="#{coverage_class(js_stats[:percentage])}">#{js_stats[:percentage]}%</td>
            </tr>
            <tr style="font-weight: bold; background: #f5f5f5;">
              <td>Total</td>
              <td>#{ruby_stats[:files] + js_stats[:files]}</td>
              <td>#{total_lines}</td>
              <td>#{total_covered}</td>
              <td class="#{coverage_class(total_percentage)}">#{total_percentage}%</td>
            </tr>
          </tbody>
        </table>
      #{'  '}
        <p><a href="../coverage/index.html">View Ruby Coverage Report</a></p>
        <p><a href="../coverage-js/lcov-report/index.html">View JavaScript Coverage Report</a></p>
      </body>
      </html>
    HTML

    File.write(File.join(@output_path, 'index.html'), html_content)
  end

  def create_json_summary(ruby_stats, js_stats)
    total_lines = ruby_stats[:lines] + js_stats[:lines]
    total_covered = ruby_stats[:covered] + js_stats[:covered]
    total_percentage = total_lines > 0 ? (total_covered.to_f / total_lines * 100).round(2) : 0

    summary = {
      timestamp: Time.now.iso8601,
      total: {
        lines: total_lines,
        covered: total_covered,
        percentage: total_percentage,
        files: ruby_stats[:files] + js_stats[:files]
      },
      ruby: ruby_stats,
      javascript: js_stats
    }

    File.write(File.join(@output_path, 'coverage-summary.json'), JSON.pretty_generate(summary))
  end

  def copy_existing_reports
    # Copy Ruby coverage report if it exists
    FileUtils.cp_r(@ruby_coverage_path, File.join(@output_path, 'ruby-coverage')) if Dir.exist?(@ruby_coverage_path)

    # Copy JavaScript coverage report if it exists
    return unless Dir.exist?(@js_coverage_path)

    FileUtils.cp_r(@js_coverage_path, File.join(@output_path, 'js-coverage'))
  end

  def coverage_class(percentage)
    if percentage >= 80
      'good'
    elsif percentage >= 60
      'warning'
    else
      'danger'
    end
  end
end
