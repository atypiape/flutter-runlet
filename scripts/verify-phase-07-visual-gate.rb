#!/usr/bin/ruby
# frozen_string_literal: true

require 'digest'
require 'json'
require 'open3'
require 'optparse'
require 'pathname'
require 'find'
require 'time'
require 'tmpdir'
require 'fileutils'
require 'zlib'
require 'securerandom'
require 'csv'

module Phase07VisualGate
  class Invalid < StandardError; end

  CASE_ROW = /\A\| (V0[1-5]-[a-zA-Z0-9-]+) \| /.freeze
  ID = /\A[A-Za-z0-9][A-Za-z0-9-]*\z/.freeze
  HASH = /\A[0-9a-f]{64}\z/.freeze
  COMMIT = /\A[0-9a-f]{40}\z/.freeze
  HEADERS = %w[Status Candidate-Commit Candidate-Bundle-SHA256 Manifest-SHA256 Reviewer Reviewed-At].freeze
  DIMENSIONS = %w[window state language appearance frame].freeze
  RECEIPT_DIMENSIONS = %w[surface state language appearance frame].freeze
  TYPES = %w[native detail motion accessibility interaction overlay original system].freeze
  EXPECTED_COUNTS = {
    'V01' => [72, 8], 'V02' => [92, 0], 'V03' => [76, 16],
    'V04' => [136, 0], 'V05' => [136, 8]
  }.freeze
  BASELINE_SHA256 = '0f3c44d25618cdac0137e788fd2db5c0fc8f24bdf0b5ff3ed5e5affe683b57e2'
  EXPORT_INDEX_SHA256 = '5a35f505e46b5ee9ef1d3e27fc07ee1ec9140e6a1330665d363f3a665358038d'
  PROJECT = 'FlutterRunlet.xcodeproj/project.pbxproj'
  PRESENTATION_BRIDGE = 'FlutterRunlet/UpdatePresentationSource.swift'
  PRESENTATION_FILES = %w[
    FlutterRunlet/AuxiliaryWindows.swift
    FlutterRunlet/LaunchPresentation.swift
    FlutterRunlet/Localizable.xcstrings
  ].freeze
  # Exact presentation inputs reviewed on native screenshots in 07-04-VISUAL-RECHECK.md.
  REVIEWED_UPDATE_PRESENTATION_SHA256 = '49142d04498e4a0e0601fd216cb1209ffac1f5f74cf75992b0b20284853fb9ed'
  PLANNING = '.planning/phases/07-settings-about-updates'
  VISUAL = '.private/phase-07/visual'
  MINIMUM_PATHS = %w[
    FlutterRunlet/FlutterRunletApp.swift
    FlutterRunlet/MainWindowView.swift
    FlutterRunlet/MenuBarPanelView.swift
    FlutterRunlet/RunletAppearance.swift
    FlutterRunlet/Assets.xcassets
    FlutterRunlet/Fonts
    FlutterRunlet/Resources
  ].freeze
  BUILD_KEY = /\A(?:ASSETCATALOG_|COMBINE_HIDPI_IMAGES\z|SWIFT_|MACOSX_DEPLOYMENT_TARGET\z|INFOPLIST|GENERATE_INFOPLIST|CURRENT_PROJECT_VERSION\z|MARKETING_VERSION\z|PRODUCT_|SDKROOT\z|baseConfigurationReference\z)/.freeze

  module_function

  def assert(condition, message)
    raise Invalid, message unless condition
  end

  def command(*args, cwd:, input: '')
    stdout, stderr, status = Open3.capture3(*args, chdir: cwd.to_s, stdin_data: input)
    assert(status.success?, "#{args.first}: #{args[1]} failed (#{status.exitstatus}): #{stderr.strip}")
    stdout
  end

  def git(root, *args)
    command('/usr/bin/git', *args, cwd: root)
  end

  def checksum(path)
    Digest::SHA256.file(path).hexdigest
  end

  def parse_json(text, label)
    JSON.parse(text)
  rescue JSON::ParserError => e
    raise Invalid, "#{label}: #{e.message}"
  end

  def plist(text, root)
    parse_json(command('/usr/bin/plutil', '-convert', 'json', '-o', '-', '--', '-', cwd: root, input: text), 'plist')
  end

  def child(root, relative, directory: false)
    assert(relative.is_a?(String) && !relative.empty? && !relative.include?("\\") && !relative.include?("\0"),
           'evidence path is invalid')
    parts = relative.split('/', -1)
    assert(parts.none? { |part| ['', '.', '..'].include?(part) }, "path outside evidence directory: #{relative}")
    path = root
    parts.each do |part|
      path = path.join(part)
      assert(!path.symlink?, "linked evidence is prohibited: #{relative}")
    end
    assert(directory ? path.directory? : path.file? && path.size.positive?, "missing or empty path: #{relative}")
    path
  end

  def rows(file)
    records = {}
    file.each_line do |line|
      match = CASE_ROW.match(line)
      next unless match

      id = match[1]
      assert(!records.key?(id), "duplicate row: #{id}")
      records[id] = line.strip.split('|', -1)[1...-1].map(&:strip)
    end
    assert(!records.empty?, "no case rows: #{file.basename}")
    records
  end

  def gate_headers(file)
    HEADERS.to_h do |name|
      values = file.read.scan(/^#{Regexp.escape(name)}: ([^\r\n]+)$/).flatten
      assert(values.size == 1 && !values.first.strip.empty?, "expected one #{name} header")
      [name, values.first.strip]
    end
  end

  def project_visual_settings(raw, root)
    objects = plist(raw, root).fetch('objects')
    target = objects.values.find { |object| object['isa'] == 'PBXNativeTarget' && object['name'] == 'FlutterRunlet' }
    assert(target, 'FlutterRunlet target missing')
    project = objects.values.find { |object| object['isa'] == 'PBXProject' }
    assert(project, 'Xcode project missing')
    settings = [project, target].map do |owner|
      configs = objects.fetch(owner.fetch('buildConfigurationList')).fetch('buildConfigurations')
      configs.to_h do |id|
        config = objects.fetch(id)
        base = config['baseConfigurationReference']
        key_values = config.fetch('buildSettings').select { |key, _| key.match?(BUILD_KEY) }
        [config.fetch('name'), { 'base' => base && objects.fetch(base), 'settings' => key_values }]
      end
    end
    resources = target.fetch('buildPhases').map do |id|
      phase = objects.fetch(id)
      next unless phase['isa'] == 'PBXResourcesBuildPhase'
      phase.fetch('files').map do |file_id|
        entry = objects.fetch(file_id)
        [objects.fetch(entry.fetch('fileRef')), entry['settings']]
      end
    end
    { settings: settings, resources: resources.compact }
  end

  def protect_visual_sources(root, commit, additional_paths)
    assert(additional_paths.is_a?(Array), 'additional visual paths must be an array')
    paths = (MINIMUM_PATHS + additional_paths).uniq
    paths.each do |path|
      assert(path.is_a?(String) && path.match?(%r{\AFlutterRunlet/[a-zA-Z0-9_./-]+\z}) &&
             path.split('/').none? { |part| ['.', '..'].include?(part) }, "invalid protected path: #{path}")
    end
    git(root, 'diff', '--quiet', commit, '--', *paths)
    git(root, 'diff', '--cached', '--quiet', commit, '--', *paths)
    assert(git(root, 'ls-files', '--others', '-z', '--', *paths).empty?, 'untracked visual resource')
    candidate = project_visual_settings(git(root, 'show', "#{commit}:#{PROJECT}"), root)
    index = project_visual_settings(git(root, 'show', ":#{PROJECT}"), root)
    current = project_visual_settings(root.join(PROJECT).read, root)
    assert(candidate == index && candidate == current, 'visual build settings or resource list changed')
    from_candidate = presentation_signature { |path| git(root, 'show', "#{commit}:#{path}") }
    from_index = presentation_signature { |path| git(root, 'show', ":#{path}") }
    from_disk = presentation_signature { |path| root.join(path).read }
    approved = [from_candidate, REVIEWED_UPDATE_PRESENTATION_SHA256]
    assert(from_index == from_disk && approved.include?(from_disk),
           'visual presentation state or wording changed without a matching reviewed snapshot')
  end

  def presentation_signature
    files = PRESENTATION_FILES.map { |path| Digest::SHA256.hexdigest(yield(path)) }
    model = Digest::SHA256.hexdigest(presentation_model(yield(PRESENTATION_BRIDGE)))
    Digest::SHA256.hexdigest(JSON.generate(files + [model]))
  end

  def presentation_model(source)
    model = source.index(/^struct UpdatePresentation: /)
    bridge = source.index("\n@MainActor\n@Observable\nfinal class UpdatePresentationSource", model || 0)
    assert(model && bridge && bridge > model, 'could not locate the protected update presentation model')
    source[model...bridge]
  end

  def bundle_tree_checksum(bundle)
    real_root = bundle.realpath
    records = []
    Find.find(bundle.to_s) do |entry|
      path = Pathname.new(entry)
      next if path == bundle

      relative = path.relative_path_from(bundle).to_s
      if path.symlink?
        assert(path.realpath.to_s.start_with?(real_root.to_s + '/'), "bundle link leaves the bundle: #{relative}")
        records << [relative, 'L', path.readlink.to_s]
      elsif path.directory?
        records << [relative, 'D']
      elsif path.file?
        records << [relative, 'F', path.stat.mode & 0o777, checksum(path)]
      else
        raise Invalid, "unexpected bundle entry: #{relative}"
      end
    end
    assert(records.any? { |record| record[1] == 'F' }, 'empty candidate bundle')
    Digest::SHA256.hexdigest(records.sort_by(&:first).map { |record| JSON.generate(record) + "\n" }.join)
  end

  def timestamp(value, label)
    Time.iso8601(value)
  rescue ArgumentError, TypeError
    raise Invalid, "invalid timestamp: #{label}"
  end

  def validate_candidate(root, visual, headers, manifest)
    commit = headers.fetch('Candidate-Commit')
    assert(commit.match?(COMMIT), 'invalid candidate commit')
    git(root, 'merge-base', '--is-ancestor', commit, 'HEAD')
    assert(git(root, 'cat-file', '-t', commit).strip == 'commit', 'candidate is not a commit')
    candidate = manifest.fetch('candidate')
    assert(candidate.fetch('commit') == commit, 'manifest points to another candidate commit')
    bundle = child(visual, candidate.fetch('bundle_path'), directory: true)
    assert(bundle.extname == '.app', 'candidate path is not an App bundle')
    sha = bundle_tree_checksum(bundle)
    assert(candidate.fetch('bundle_sha256') == sha &&
           headers.fetch('Candidate-Bundle-SHA256') == sha, 'candidate Bundle digest differs')
    info = plist(child(bundle, 'Contents/Info.plist').binread, root)
    executable = child(bundle, "Contents/MacOS/#{info.fetch('CFBundleExecutable')}")
    expect = { 'bundle_identifier' => 'CFBundleIdentifier', 'version' => 'CFBundleShortVersionString', 'build' => 'CFBundleVersion' }
    expect.each { |key, info_key| assert(candidate.fetch(key) == info.fetch(info_key), "candidate #{key} differs") }
    assert(executable.executable? && candidate.fetch('executable_sha256') == checksum(executable),
           'candidate executable differs')
    assert(candidate.fetch('configuration') == 'Debug', 'expected a Debug visual candidate')
    environment = candidate.fetch('environment')
    %w[macos xcode architecture].each do |key|
      assert(environment.fetch(key).is_a?(String) && !environment.fetch(key).strip.empty?,
             "missing candidate environment: #{key}")
    end
    assert(environment.fetch('scale') == 1 && environment.fetch('languages').sort == %w[en zh-Hans] &&
           environment.fetch('appearances').sort == %w[dark light], 'candidate environment does not cover the visual matrix')
    protect_visual_sources(root, commit, candidate.fetch('additional_visual_paths'))
    [commit, sha, candidate.fetch('executable_sha256'), executable.to_s]
  end

  def validate_png(path)
    dimensions = nil
    data_bytes = 0
    path.open('rb') do |file|
      assert(file.read(8) == "\x89PNG\r\n\x1a\n".b, "invalid PNG signature: #{path.basename}")
      loop do
        header = file.read(8)
        assert(header&.bytesize == 8, "incomplete PNG: #{path.basename}")
        size, kind = header.unpack('Na4')
        assert(size <= path.size - file.pos - 4, "invalid PNG chunk length: #{path.basename}")
        bytes = file.read(size)
        crc = file.read(4).unpack1('N')
        assert(Zlib.crc32(bytes, Zlib.crc32(kind)) == crc, "invalid PNG chunk checksum: #{path.basename}")
        yield(kind, bytes) if block_given?
        unless dimensions
          assert(kind == 'IHDR' && size == 13, "missing PNG header: #{path.basename}")
          dimensions = bytes.unpack('NN')
          assert(dimensions.all? { |n| n > 8 }, "invalid PNG dimensions: #{path.basename}")
        end
        data_bytes += size if kind == 'IDAT'
        next unless kind == 'IEND'

        assert(data_bytes.positive? && size.zero? && file.eof?, "invalid PNG ending: #{path.basename}")
        break
      end
    end
    dimensions
  end

  def validate_native_capture(visual, item, path, capture_ids, executable_sha256, executable_path)
    id = item.fetch('id')
    size = validate_png(path)
    receipt = child(visual, item.fetch('receipt_path'))
    assert(item.fetch('receipt_sha256') == checksum(receipt), "capture receipt digest differs: #{id}")
    proof = parse_json(receipt.read, id)
    capture_id = proof.fetch('capture_id')
    assert(capture_id.match?(/\A[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/) && !capture_ids.key?(capture_id),
           "invalid or reused capture event: #{id}")
    capture_ids[capture_id] = true
    assert(proof.fetch('case_id') == item.fetch('case_id') &&
           proof.values_at(*RECEIPT_DIMENSIONS) == item.values_at(*DIMENSIONS) &&
           proof.fetch('candidate_executable_sha256') == executable_sha256 &&
           proof.fetch('candidate_executable') == executable_path &&
           proof.fetch('png_sha256') == item.fetch('sha256') &&
           proof.fetch('captured_at') == item.fetch('captured_at') &&
           proof.fetch('pixel_size') == size, "capture receipt belongs to other evidence: #{id}")
    actual_language = proof.fetch('observed_language', proof.fetch('language'))
    actual_surface = proof.fetch('observed_surface', proof.fetch('surface'))
    assert(%w[en zh-Hans].include?(actual_language) &&
           item.fetch('observed_language') == actual_language &&
           item.fetch('observed_surface') == actual_surface,
           "capture presentation metadata differs: #{id}")
    role = item.fetch('role')
    assert(%w[primary supporting].include?(role) &&
           (role != 'primary' || actual_language == item.fetch('language')), "case screenshot language differs: #{id}")
    window = proof.fetch('window')
    assert(proof.fetch('candidate_pid').positive? &&
           proof.fetch('candidate_pid') == window.fetch('kCGWindowOwnerPID') &&
           window.fetch('kCGWindowNumber').positive? && window.fetch('kCGWindowIsOnscreen') == true,
           "capture receipt does not describe a visible candidate window: #{id}")
    assert(timestamp(proof.fetch('started_at'), id) <= timestamp(item.fetch('captured_at'), id),
           "invalid capture interval: #{id}")
    assert(proof.fetch('accessibility_after_capture').is_a?(Array) &&
           !proof.fetch('accessibility_after_capture').empty?, "capture has no native AX observation: #{id}")
    title = window.fetch('kCGWindowName', '').sub(/\A(?:FlutterRunlet\s*)?(?:设置|Settings)\z/, 'settings')
    # The captured pixel dimensions can settle after the pre-capture CG geometry query.
    surface = [size, window.fetch('kCGWindowLayer'), title]
    [proof.fetch('candidate_pid'), window.fetch('kCGWindowNumber'), proof.fetch('captured_at'), surface]
  end

  def verify_references(visual, manifest)
    export_index = child(visual, manifest.fetch('reference_index'))
    assert(checksum(export_index) == EXPORT_INDEX_SHA256, 'approved export index differs')
    approved = CSV.read(export_index.to_s, headers: true, col_sep: "\t").select { |row| row['scale'] == '1' }
    references = manifest.fetch('references')
    assert(approved.map { |row| row.fetch('id') }.sort == references.keys.sort, 'approved 1× originals are incomplete')
    approved.each do |row|
      id = row.fetch('id')
      item = references.fetch(id)
      image = child(visual, item.fetch('path'))
      assert(item.fetch('sha256') == row.fetch('sha256') && checksum(image) == item.fetch('sha256'),
             "approved original digest differs: #{id}")
      size = %w[pixel_width pixel_height].map { |key| Integer(row.fetch(key), 10) }
      assert(validate_png(image) == size, "approved original dimensions differ: #{id}")
      item['pixel_size'] = size
    end
    references
  end

  def verify_evidence(visual, manifest, identity, reviewed_at)
    evidence = {}
    paths = {}
    native_hashes = {}
    capture_ids = {}
    capture_events = {}
    manifest.fetch('evidence').each do |item|
      id = item.fetch('id')
      relative = item.fetch('path')
      kind = item.fetch('type')
      assert(id.is_a?(String) && id.match?(ID) && !evidence.key?(id), "invalid or repeated evidence ID: #{id}")
      assert(TYPES.include?(kind) && !paths.key?(relative), "invalid type or reused file: #{relative}")
      path = child(visual, relative)
      sha = item.fetch('sha256')
      assert(sha.match?(HASH) && checksum(path) == sha, "evidence digest differs: #{id}")
      assert(identity.first(2) == item.values_at('candidate_commit', 'candidate_bundle_sha256'), "evidence from another build: #{id}")
      assert(timestamp(item.fetch('captured_at'), id) <= reviewed_at, "evidence generated after review: #{id}")
      case kind
      when 'native'
        pid, window, time, surface = validate_native_capture(visual, item, path, capture_ids, identity[2], identity[3])
        item['capture_event'] = [pid, window, time]
        item['pixel_size'] = surface.first
        item['native_path'] = path
        assert(!capture_events.key?(item['capture_event']), "candidate capture event reused: #{id}")
        capture_events[item['capture_event']] = id
        if (previous = native_hashes[sha])
          item['same_pixels'] = previous['same_pixels'] = true
          same_combination = surface == previous.fetch('capture_surface') &&
                             item.values_at('observed_language', 'appearance') ==
                             previous.values_at('observed_language', 'appearance')
          assert(same_combination && item.fetch('same_pixels_reason', '').strip.size >= 8,
                 "reused native screenshot bytes without documented independent recapture: #{id}")
        else
          item['capture_surface'] = surface
          native_hashes[sha] = item
        end
      when 'detail', 'overlay', 'original'
        validate_png(path)
      when 'system'
        validate_png(path)
        receipt = child(visual, item.fetch('receipt_path'))
        assert(checksum(receipt) == item.fetch('receipt_sha256'), "system region receipt differs: #{id}")
        record = parse_json(receipt.read, id)
        window = record.fetch('window')
        assert(item.fetch('window') == 'general' && item.fetch('state') == 'login-system-settings' &&
               window.fetch('kCGWindowNumber').positive? && window.fetch('kCGWindowOwnerPID').positive? &&
               timestamp(record.fetch('captured_at'), id) == timestamp(item.fetch('captured_at'), id),
               "system region receipt does not match the login settings case: #{id}")
      when 'motion'
        item['record'] = parse_json(path.read, id)
      when 'accessibility', 'interaction'
        data = parse_json(path.read, id)
        assert((data.is_a?(Hash) || data.is_a?(Array)) && !data.empty?, "empty evidence: #{id}")
        item['record'] = data
      end
      paths[relative] = true
      evidence[id] = item
    end
    evidence
  end

  def verify_interaction(item, natives)
    record = item.fetch('record')
    id = item.fetch('case_id')
    assert(record.fetch('case_id') == id, "interaction belongs to another case: #{id}")
    steps = record.fetch('steps')
    assert(steps.is_a?(Array) && !steps.empty?, "missing observed action: #{id}")
    times = steps.map do |step|
      assert(step.fetch('action').is_a?(String) && !step.fetch('action').strip.empty? &&
             !step.fetch('observed').to_s.strip.empty?, "missing action or observation: #{id}")
      timestamp(step.fetch('at'), id)
    end
    assert(times == times.sort && times.last <= timestamp(item.fetch('captured_at'), id),
           "invalid interaction chronology: #{id}")
    assert(natives.any? { |native| native.fetch('capture_event').first == record.fetch('candidate_pid') },
           "interaction has no screenshot from its candidate process: #{id}")
  end

  def paeth_predictor(left, above, diagonal)
    prediction = left + above - diagonal
    left_error = (prediction - left).abs
    above_error = (prediction - above).abs
    diagonal_error = (prediction - diagonal).abs
    return left if left_error <= above_error && left_error <= diagonal_error

    above_error <= diagonal_error ? above : diagonal
  end

  def motion_crop_checksum(path, crop)
    compressed = ''.b
    dimensions = validate_png(path) do |kind, bytes|
      if kind == 'IHDR'
        width, height, depth, color, method, filter, interlace = bytes.unpack('NNCCCCC')
        assert([[400, 412], [520, 520]].include?([width, height]) &&
               [depth, color, method, filter, interlace] == [8, 6, 0, 0, 0],
               "unexpected native motion PNG format: #{path.basename}")
      end
      compressed << bytes if kind == 'IDAT'
    end
    region_size(crop, dimensions, path.basename)
    width, height = dimensions
    x, y, crop_width, crop_height = crop
    row_stride = width * 4 + 1
    byte_limit = row_stride * height
    scanlines = ''.b
    decoder = Zlib::Inflate.new
    begin
      decoder.inflate(compressed) do |part|
        assert(scanlines.bytesize + part.bytesize <= byte_limit, "oversized PNG image: #{path.basename}")
        scanlines << part
      end
      assert(decoder.finished? && scanlines.bytesize == byte_limit, "incomplete PNG pixels: #{path.basename}")
    ensure
      decoder.close
    end

    crop_start = x * 4
    crop_length = crop_width * 4
    needed_bytes = crop_start + crop_length
    previous = "\0".b * needed_bytes
    digest = Digest::SHA256.new
    (y + crop_height).times do |line|
      offset = line * row_stride
      filter = scanlines.getbyte(offset)
      assert(filter <= 4, "unknown PNG scanline filter: #{path.basename}")
      row = scanlines.byteslice(offset + 1, needed_bytes)
      if filter.nonzero?
        needed_bytes.times do |column|
          left = column >= 4 ? row.getbyte(column - 4) : 0
          above = previous.getbyte(column)
          diagonal = column >= 4 ? previous.getbyte(column - 4) : 0
          prediction = case filter
                       when 1 then left
                       when 2 then above
                       when 3 then (left + above) / 2
                       when 4 then paeth_predictor(left, above, diagonal)
                       end
          row.setbyte(column, (row.getbyte(column) + prediction) & 255)
        end
      end
      digest.update(row.byteslice(crop_start, crop_length)) if line >= y
      previous = row
    end
    digest.hexdigest
  rescue Zlib::Error => e
    raise Invalid, "invalid PNG pixels: #{path.basename}: #{e.message}"
  end

  def verify_motion(item, natives)
    record = item.fetch('record')
    id = item.fetch('case_id')
    assert(record.fetch('case_id') == id, "motion belongs to another case: #{id}")
    frame_ids = record.fetch('frames')
    assert(frame_ids.is_a?(Array) && frame_ids.size >= 4 && frame_ids.uniq == frame_ids,
           "missing independent motion frames: #{id}")
    images = natives.to_h { |native| [native.fetch('id'), native] }
    frames = frame_ids.map { |frame_id| images.fetch(frame_id) }
    events = frames.map { |frame| frame.fetch('capture_event') }
    times = events.map { |event| timestamp(event.last, id) }
    crops = record.fetch('button_sha256')
    expected_crop = item.fetch('window') == 'about' ? [142, 223, 116, 30] : [375, 112, 116, 30]
    assert(record.fetch('button_crop') == expected_crop && crops.keys.sort == frame_ids.sort &&
           crops.values.all? { |value| value.match?(HASH) } && crops.values.uniq.size >= 4,
           "spinner button samples do not demonstrate motion: #{id}")
    assert(events.map { |event| event.first(2) }.uniq.size == 1 &&
           times.each_cons(2).all? { |a, b| a < b } && times.last - times.first >= 1.6 &&
           frames.map { |frame| frame.fetch('sha256') }.uniq.size >= 4,
           "motion has insufficient timing, window continuity or image changes: #{id}")
    actual_pixels = frames.map { |frame| motion_crop_checksum(frame.fetch('native_path'), expected_crop) }
    assert(actual_pixels.uniq.size >= 4, "spinner button pixels do not demonstrate motion: #{id}")
  end

  def matches_case(item, fields)
    item.fetch('case_id') == fields[0] && item.values_at(*DIMENSIONS) == fields[2, DIMENSIONS.size]
  end

  def region_size(crop, pixels, id)
    assert(crop.is_a?(Array) && crop.size == 4 && crop.all? { |value| value.is_a?(Integer) },
           "invalid region coordinates: #{id}")
    x, y, width, height = crop
    assert(x >= 0 && y >= 0 && width.positive? && height.positive? &&
           x + width <= pixels[0] && y + height <= pixels[1], "region outside source image: #{id}")
    [width, height]
  end

  def verify_cases(baseline, gate, evidence, expected_counts, references, manifest_verdicts, manifest_cases)
    expected = rows(baseline)
    verdicts = rows(gate)
    assert(expected.keys.sort == verdicts.keys.sort, 'gate case IDs do not match the baseline')
    assert(manifest_verdicts.keys.sort == verdicts.keys.sort, 'manifest case IDs do not match the gate')
    assert(manifest_cases.keys.sort == expected.keys.sort, 'manifest expectations do not match the baseline')
    counts = expected.values.group_by { |fields| fields[0][0, 3] }.transform_values do |fields|
      [fields.count { |row| row[1] == 'REQUIRED' }, fields.count { |row| row[1] == 'N/A' }]
    end
    assert(counts == expected_counts, 'baseline does not cover the frozen visual matrix')
    referenced = []
    groups = []
    expected.each do |id, fields|
      decision = verdicts.fetch(id)
      assert(fields.size == 12 && decision.size == 4 && !decision.last.empty?, "missing case columns: #{id}")
      expected_case = %w[entry input reference expected required_evidence].zip(fields[7, 5]).to_h
      assert(manifest_cases.fetch(id) == expected_case, "manifest changed the case expectations: #{id}")
      ids = decision[2] == '—' ? [] : decision[2].split(',').map(&:strip)
      assert(manifest_verdicts.fetch(id) == { 'status' => decision[1], 'evidence' => ids, 'note' => decision[3] },
             "manifest verdict does not match the gate: #{id}")
      if fields[1] == 'N/A'
        assert(decision[1] == 'N/A' && decision[2] == '—' && decision[3] == fields[10],
               "different applicability or reason: #{id}")
        next
      end
      groups << id[0, 3]
      assert(fields[1] == 'REQUIRED' && decision[1] == 'PASS', "case failed or blocked: #{id}")
      assert(!decision.last.match?(/\b(?:TBD|TODO|placeholder)\b|待核对|待复核|未验证|未验收/i),
             "case verdict describes incomplete review: #{id}")
      assert(!ids.empty? && ids.uniq == ids, "missing or reused case evidence: #{id}")
      items = ids.map { |proof_id| evidence.fetch(proof_id) }
      assert(items.all? { |item| matches_case(item, fields) }, "evidence assigned to wrong case: #{id}")
      types = items.map { |item| item.fetch('type') }
      assert(types.include?('native'), "missing real App screenshot: #{id}")
      if fields[3] == 'login-system-settings'
        assert(types.include?('system'), "missing independent System Settings area: #{id}")
      end
      assert(fields[6] != 'sequence' || types.include?('motion'), "missing continuous frame recording: #{id}")
      originals = fields[9].scan(/Figma 原图\s+((?:P07-[FU][0-9]{2};?)+)/)
                        .flatten.flat_map { |value| value.split(';') }
      compared = items.select { |item| item['type'] == 'overlay' }.map { |item| item.fetch('reference_id') }
      assert((originals - compared).empty?,
             "missing matching original comparison: #{id}")
      assert(types.include?('detail') || types.include?('overlay'), "missing region evidence: #{id}")
      natives = items.select { |item| item['type'] == 'native' }
      assert(natives.any? { |item| item['role'] == 'primary' }, "missing primary native screenshot: #{id}")
      if fields[11].match?(/AX|动作|操作|序列|前后|录像|状态记录|偏好|SDK|原文|输入行为|URL|访达|Bundle|选中记录/)
        assert(types.include?('interaction'), "missing case-specific operation evidence: #{id}")
      end
      if natives.any? { |native| native['same_pixels'] }
        assert(types.include?('interaction'), "equal pixels need separate operation evidence: #{id}")
      end
      items.each do |item|
        verify_motion(item, natives) if item['type'] == 'motion'
        verify_interaction(item, natives) if item['type'] == 'interaction'
        if %w[detail overlay system].include?(item['type'])
          native = natives.find { |frame| frame.fetch('id') == item.fetch('native_id') }
          assert(native, "region evidence references another case: #{id}")
          next if item['type'] == 'system'

          size = region_size(item.fetch('native_crop'), native.fetch('pixel_size'), id)
          if item['type'] == 'overlay'
            approved = references.fetch(item.fetch('reference_id')).fetch('pixel_size')
            reference_crop = item.fetch('reference_crop')
            reference_size = reference_crop ? region_size(reference_crop, approved, id) : approved
            assert(size == reference_size, "comparison regions are not at the same scale: #{id}")
          end
        end
      end
      items.select { |item| %w[overlay original].include?(item['type']) }.each do |item|
        source = item.fetch('reference_id')
        assert(originals.include?(source) && fields[4] == 'zh-Hans' && fields[5] == 'dark',
               "reference mismatch: #{id}")
        assert(item.fetch('reference_sha256') == references.fetch(source).fetch('sha256'),
               "reference digest mismatch: #{id}")
      end
      referenced.concat(ids)
    end
    assert(groups.uniq.sort == %w[V01 V02 V03 V04 V05], 'an entire verification group is missing')
    assert(referenced.uniq.sort == evidence.keys.sort, 'manifest contains orphaned or unrelated evidence')
    groups.size
  end

  def verify(root, gate: nil, baseline: nil, manifest: nil, expected_counts: EXPECTED_COUNTS)
    root = Pathname.new(root).realpath
    visual = child(root, VISUAL, directory: true)
    gate ||= root.join(PLANNING, '07-VISUAL-GATE.md')
    baseline ||= root.join(PLANNING, '07-VISUAL-BASELINE.md')
    manifest ||= visual.join('manifest.json')
    assert(manifest.expand_path.to_s.start_with?(visual.to_s + '/'), 'manifest not in private visual directory')
    manifest = child(visual, manifest.expand_path.relative_path_from(visual).to_s)
    headers = gate_headers(gate)
    assert(headers.fetch('Status') == 'PASS', 'visual gate is not PASS')
    reviewed_at = timestamp(headers.fetch('Reviewed-At'), 'Reviewed-At')
    assert(reviewed_at <= Time.now, 'visual review time is in the future')
    assert(checksum(manifest) == headers.fetch('Manifest-SHA256'), 'manifest digest differs')
    document = parse_json(manifest.read, 'manifest')
    assert(document.fetch('schema_version') == 2, 'unsupported evidence schema')
    assert(document.fetch('baseline_sha256') == checksum(baseline), 'baseline digest differs')
    production = expected_counts == EXPECTED_COUNTS
    if production
      assert(document.fetch('baseline_sha256') == BASELINE_SHA256, 'frozen baseline was modified')
    end
    identity = validate_candidate(root, visual, headers, document)
    references = production ? verify_references(visual, document) : {}
    evidence = verify_evidence(visual, document, identity, reviewed_at)
    verify_cases(baseline, gate, evidence, expected_counts, references, document.fetch('verdicts'),
                 document.fetch('cases'))
  end

  def fixture_png(red)
    chunk = lambda do |type, bytes|
      payload = type.b + bytes
      [bytes.bytesize].pack('N') + payload + [Zlib.crc32(payload)].pack('N')
    end
    pixel_rows = Array.new(20) do |y|
      [0].pack('C') + (0...20).map { |x| [red, x * 9, y * 7].pack('CCC') }.join
    end.join
    "\x89PNG\r\n\x1a\n".b +
      chunk.call('IHDR', [20, 20, 8, 2, 0, 0, 0].pack('NNCCCCC')) +
      chunk.call('IDAT', Zlib.deflate(pixel_rows)) +
      chunk.call('IEND', ''.b)
  end

  def fixture_motion_frames(root, crop, changed_coordinates)
    width = 400
    height = 412
    chunk = lambda do |type, bytes|
      payload = type.b + bytes
      [bytes.bytesize].pack('N') + payload + [Zlib.crc32(payload)].pack('N')
    end
    rows = ("\0".b + [32, 40, 48, 255].pack('C4') * width) * height
    case_id = 'V04-about-check-motion-en-dark'
    frames = 4.times.map do |index|
      data = rows.dup
      x, y = changed_coordinates
      data.setbyte(y * (width * 4 + 1) + x * 4 + 1, index * 16)
      path = root.join("motion-fixture-#{index}.png")
      path.binwrite("\x89PNG\r\n\x1a\n".b +
                    chunk.call('IHDR', [width, height, 8, 6, 0, 0, 0].pack('NNCCCCC')) +
                    chunk.call('IDAT', Zlib.deflate(data)) + chunk.call('IEND', ''.b))
      { 'id' => "frame-#{index}", 'native_path' => path, 'sha256' => checksum(path),
        'capture_event' => [123, 456, "2026-11-15T00:00:0#{index}Z"] }
    end
    declared = frames.to_h { |frame| [frame.fetch('id'), frame.fetch('sha256')] }
    record = { 'case_id' => case_id, 'frames' => declared.keys, 'button_crop' => crop, 'button_sha256' => declared }
    [{ 'case_id' => case_id, 'window' => 'about', 'record' => record }, frames]
  end

  def self_test(project_file)
    original_project = File.binread(project_file)
    Dir.mktmpdir('phase-07-gate-fixtures') do |temp|
      root = Pathname.new(temp).realpath
      git(root, 'init', '-q')
      git(root, 'config', 'user.name', 'Gate Fixture')
      git(root, 'config', 'user.email', 'gate-test@example.invalid')
      git(root, 'config', 'commit.gpgsign', 'false')
      project = root.join(PROJECT)
      project.dirname.mkpath
      project.binwrite(original_project)
      visual_inputs = (MINIMUM_PATHS + PRESENTATION_FILES).map do |path|
        file = root.join(path)
        file = file.join('fixture.asset') if %w[Assets.xcassets Fonts Resources].include?(file.basename.to_s)
        file.dirname.mkpath
        file.write("visual fixture\n")
        file
      end
      bridge = root.join(PRESENTATION_BRIDGE)
      bridge.write("struct UpdatePresentation: Equatable {}\n\n@MainActor\n@Observable\nfinal class UpdatePresentationSource {}\n")
      git(root, 'add', '--', PROJECT, 'FlutterRunlet')
      git(root, 'commit', '-qm', 'synthetic local gate fixture')
      commit = git(root, 'rev-parse', 'HEAD').strip

      visual = root.join(VISUAL)
      bundle = visual.join('Candidate', 'FlutterRunlet.app')
      exe = bundle.join('Contents', 'MacOS', 'FlutterRunlet')
      exe.dirname.mkpath
      exe.write("synthetic executable used solely to exercise gate validation\n")
      exe.chmod(0o755)
      bundle.join('Contents', 'Info.plist').write(JSON.generate(
        'CFBundleExecutable' => 'FlutterRunlet',
        'CFBundleIdentifier' => 'invalid.example.VisualGateFixture',
        'CFBundleShortVersionString' => '0.2.0',
        'CFBundleVersion' => '256'
      ))
      sha = bundle_tree_checksum(bundle)
      baseline = root.join(PLANNING, '07-VISUAL-BASELINE.md')
      baseline.dirname.mkpath
      gate = baseline.dirname.join('07-VISUAL-GATE.md')
      manifest = visual.join('manifest.json')
      fixture_dimensions = %w[general sample zh-Hans dark static]
      case_ids = (1..5).map { |number| "V0#{number}-general-sample-zh-Hans-dark" }
      case_rows = case_ids.map do |id|
        ([id, 'REQUIRED'] + fixture_dimensions + ['Settings', 'fixture', 'Component', 'check', 'image']).join(' | ')
      end
      baseline.write(case_rows.map { |row| "| #{row} |\n" }.join)
      evidence = case_ids.each_with_index.map do |id, index|
        png = visual.join("case-#{index}.png")
        png.binwrite(fixture_png(index * 10))
        capture = visual.join("case-#{index}.json")
        captured_at = (Time.now.utc - 10 + index * 0.01).iso8601(6)
        capture.write(JSON.generate(Hash[RECEIPT_DIMENSIONS.zip(fixture_dimensions)].merge(
          'capture_id' => SecureRandom.uuid, 'candidate_pid' => 55, 'captured_at' => captured_at,
          'started_at' => (Time.now.utc - 11).iso8601,
          'case_id' => id, 'candidate_executable_sha256' => checksum(exe), 'candidate_executable' => exe.to_s,
          'png_sha256' => checksum(png), 'pixel_size' => [20, 20],
          'accessibility_after_capture' => [{ 'AXRole' => 'AXWindow' }],
          'window' => {'kCGWindowOwnerPID' => 55, 'kCGWindowNumber' => 63, 'kCGWindowIsOnscreen' => true,
                       'kCGWindowBounds' => {'Width' => 20, 'Height' => 20}, 'kCGWindowLayer' => 0}
        )))
        Hash[DIMENSIONS.zip(fixture_dimensions)].merge(
          'id' => "case-#{index}", 'case_id' => id, 'type' => 'native', 'path' => png.basename.to_s,
          'sha256' => checksum(png), 'candidate_commit' => commit, 'candidate_bundle_sha256' => sha,
          'receipt_path' => capture.basename.to_s, 'receipt_sha256' => checksum(capture),
          'captured_at' => captured_at, 'observed_language' => 'zh-Hans', 'observed_surface' => 'general',
          'role' => 'primary'
        )
      end
      details = evidence.map do |item|
        path = visual.join(item.fetch('id') + '-detail.png')
        path.binwrite(fixture_png(1))
        item.reject { |key, _| key.start_with?('receipt_') }.merge(
          'id' => item.fetch('id') + '-detail', 'path' => path.basename.to_s,
          'native_id' => item.fetch('id'), 'native_crop' => [0, 0, 20, 20], 'type' => 'detail', 'sha256' => checksum(path)
        )
      end
      operations = evidence.each_with_index.map do |item, index|
        path = visual.join("case-#{index}-action.json")
        path.write(JSON.generate('case_id' => item.fetch('case_id'), 'candidate_pid' => 55,
                                 'steps' => [{'at' => item.fetch('captured_at'), 'action' => 'fixture input',
                                              'observed' => 'fixture output'}]))
        item.reject { |key, _| key.start_with?('receipt_') }.merge(
          'id' => item.fetch('id') + '-action', 'path' => path.basename.to_s,
          'type' => 'interaction', 'sha256' => checksum(path)
        )
      end
      document = {
        'schema_version' => 2,
        'baseline_sha256' => checksum(baseline),
        'candidate' => {
          'commit' => commit, 'bundle_path' => bundle.relative_path_from(visual).to_s,
          'bundle_sha256' => sha, 'configuration' => 'Debug', 'bundle_identifier' => 'invalid.example.VisualGateFixture',
          'version' => '0.2.0', 'build' => '256', 'executable_sha256' => checksum(exe), 'additional_visual_paths' => [],
          'environment' => {'macos' => 'fixture', 'xcode' => 'fixture', 'architecture' => 'fixture', 'scale' => 1,
                            'languages' => %w[en zh-Hans], 'appearances' => %w[dark light]}
        },
        'evidence' => evidence + details + operations
      }
      fixture_counts = case_ids.to_h { |id| [id[0, 3], [1, 0]] }
      verify_fixture = -> { verify(root, expected_counts: fixture_counts) }
      document['verdicts'] = case_ids.each_with_index.to_h do |id, i|
        [id, {'status' => 'PASS', 'evidence' => ["case-#{i}", "case-#{i}-detail", "case-#{i}-action"],
              'note' => 'tested'}]
      end
      document['cases'] = case_ids.to_h do |id|
        [id, {'entry' => 'Settings', 'input' => 'fixture', 'reference' => 'Component', 'expected' => 'check',
              'required_evidence' => 'image'}]
      end
      write_gate = lambda do
        manifest.write(JSON.generate(document))
        headers = ['Status: PASS', "Candidate-Commit: #{commit}", "Candidate-Bundle-SHA256: #{sha}",
                   "Manifest-SHA256: #{checksum(manifest)}", 'Reviewer: synthetic fixture',
                   "Reviewed-At: #{Time.now.utc.iso8601}"]
        results = case_ids.each_with_index.map do |id, i|
          "| #{id} | PASS | case-#{i},case-#{i}-detail,case-#{i}-action | tested |"
        end
        gate.write((headers + results).join("\n") + "\n")
      end
      expect_invalid = lambda do |description, match|
        begin
          verify_fixture.call
        rescue Invalid, KeyError, SystemCallError => e
          raise "wrong rejection for #{description}: #{e.message}" unless e.message.match?(match)
        else
          raise "unexpected acceptance: #{description}"
        end
      end

      write_gate.call
      assert(verify_fixture.call == 5, 'valid verifier fixture was not accepted')
      executable_bytes = exe.binread
      exe.binwrite(executable_bytes + 'changed')
      expect_invalid.call('replaced candidate executable', /Bundle digest differs/)
      exe.binwrite(executable_bytes)
      shot = visual.join('case-0.png')
      shot_bytes = shot.binread
      shot.delete
      expect_invalid.call('missing screenshot', /missing or empty path/)
      shot.binwrite(shot_bytes + 'changed')
      expect_invalid.call('modified screenshot', /digest differs/)
      shot.binwrite(shot_bytes)

      clean_gate = gate.read
      gate.write(clean_gate.sub('Status: PASS', 'Status: FAIL'))
      expect_invalid.call('failed gate', /not PASS/)
      gate.write(clean_gate.sub(commit, '0' * 40))
      expect_invalid.call('wrong candidate commit', /merge-base failed/)
      gate.write(clean_gate.lines.reject { |line| line.include?('case-4,') }.join)
      expect_invalid.call('omitted case with PASS header', /case IDs do not match/)
      gate.write(clean_gate.gsub('case-0,', 'case-1,'))
      expect_invalid.call('manifest verdict differs from Markdown', /manifest verdict does not match/)
      case_zero = document.fetch('verdicts').fetch(case_ids.first)
      case_zero.fetch('evidence')[0] = 'case-1'
      manifest.write(JSON.generate(document))
      gate.write(gate.read.sub(/^Manifest-SHA256: .*$/, "Manifest-SHA256: #{checksum(manifest)}"))
      expect_invalid.call('reused another valid case image', /wrong case/)
      case_zero.fetch('evidence')[0] = 'case-0'
      write_gate.call

      first, second = evidence[0], evidence[1]
      second_png = visual.join(second.fetch('path'))
      second_receipt = visual.join(second.fetch('receipt_path'))
      clean_second = [second.dup, second_png.binread, second_receipt.binread]
      second_png.binwrite(shot_bytes)
      receipt = JSON.parse(second_receipt.read)
      receipt['png_sha256'] = second['sha256'] = first.fetch('sha256')
      second_receipt.write(JSON.generate(receipt))
      second['receipt_sha256'] = checksum(second_receipt)
      write_gate.call
      expect_invalid.call('same image without independent recapture explanation', /reused native screenshot bytes/)
      second['same_pixels_reason'] = 'Two different entry methods produce the same visible layout'
      write_gate.call
      assert(verify_fixture.call == 5, 'a separately captured unchanged appearance should remain valid')
      receipt['capture_id'] = JSON.parse(visual.join(first.fetch('receipt_path')).read).fetch('capture_id')
      second_receipt.write(JSON.generate(receipt))
      second['receipt_sha256'] = checksum(second_receipt)
      write_gate.call
      expect_invalid.call('copying the same capture event', /reused capture event/)
      second.replace(clean_second[0])
      second_png.binwrite(clean_second[1])
      second_receipt.binwrite(clean_second[2])
      write_gate.call

      asset = visual_inputs.find { |input| input.to_s.include?('/Assets.xcassets/') }
      asset.dirname.join('new.asset').write('new asset')
      expect_invalid.call('untracked asset', /untracked visual resource/)
      asset.dirname.join('new.asset').delete
      asset.delete
      expect_invalid.call('removed asset', /git: diff failed/)
      git(root, 'checkout', '--', asset.relative_path_from(root).to_s)
      [root.join('FlutterRunlet/AuxiliaryWindows.swift'), visual_inputs.find { |input| input.to_s.include?('/Fonts/') }].each do |input|
        input.write('uncommitted visual change')
        expect_invalid.call('uncommitted view or font', /git: diff failed|visual presentation state or wording changed/)
        git(root, 'checkout', '--', input.relative_path_from(root).to_s)
      end

      network = root.join('FlutterRunlet', 'UpdateService.swift')
      network.write('private local connection fixture')
      bridge.write(bridge.read.sub('final class UpdatePresentationSource {}',
                                   'final class UpdatePresentationSource { func connect() {} }'))
      git(root, 'add', '--', network.relative_path_from(root).to_s, PRESENTATION_BRIDGE)
      git(root, 'commit', '-qm', 'add non-visual networking fixture')
      assert(verify_fixture.call == 5, 'a non-visual addition invalidated the visual fixture')
      bridge.write(bridge.read.sub('UpdatePresentation: Equatable {}',
                                   'UpdatePresentation: Equatable { var unexpectedLabel = "changed" }'))
      expect_invalid.call('visual state model changed inside the bridge', /presentation state or wording changed/)

      crop = [142, 223, 116, 30]
      item, frames = fixture_motion_frames(root, crop, [150, 230])
      verify_motion(item, frames)
      item, frames = fixture_motion_frames(root, crop, [0, 0])
      begin
        verify_motion(item, frames)
      rescue Invalid => e
        assert(e.message.include?('spinner button pixels'), 'wrong static spinner rejection')
      else
        raise Invalid, 'self-test accepted a fixed spinner in changing windows'
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    args = {}
    self_test = false
    parser = OptionParser.new do |options|
      %w[gate baseline manifest].each do |key|
        options.on("--#{key} PATH") { |path| args[key.to_sym] = Pathname.new(path).expand_path }
      end
      options.on('--self-test') { self_test = true }
    end
    parser.parse!
    Phase07VisualGate.assert(ARGV.empty?, 'unexpected positional arguments')
    root = Phase07VisualGate.git(Dir.pwd, 'rev-parse', '--show-toplevel').strip
    if self_test
      Phase07VisualGate.assert(args.empty?, '--self-test does not accept evidence paths')
      Phase07VisualGate.self_test(Pathname.new(root).join(Phase07VisualGate::PROJECT))
      puts 'Visual gate self-test passed; no review decision was generated'
    else
      count = Phase07VisualGate.verify(root, **args)
      puts "VISUAL PASS: #{count} required cases verified"
    end
  rescue Phase07VisualGate::Invalid, KeyError, TypeError, NoMethodError, SystemCallError, OptionParser::ParseError => e
    warn "VISUAL BLOCKED: #{e.message}"
    exit 1
  end
end
