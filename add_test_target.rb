#!/usr/bin/env ruby
# add_test_target.rb
# Adds a SafeWalkTests unit test target to the SafeWalk.xcodeproj

require 'xcodeproj'

project_path = 'SafeWalk.xcodeproj'
project      = Xcodeproj::Project.open(project_path)

# ── Guard: don't add if target already exists ─────────────────────────────────
if project.targets.map(&:name).include?('SafeWalkTests')
  puts "⚠️  SafeWalkTests target already exists — nothing to do."
  exit 0
end

main_target = project.targets.find { |t| t.name == 'SafeWalk' }
abort("❌ Could not find main SafeWalk target") unless main_target

# ── Create the test target ────────────────────────────────────────────────────
test_target = project.new_target(
  :unit_test_bundle,
  'SafeWalkTests',
  :ios,
  '16.0'
)

# ── Add test files to the target ─────────────────────────────────────────────
test_group = project.main_group.find_subpath('SafeWalkTests') ||
             project.main_group.new_group('SafeWalkTests', 'SafeWalkTests')

test_files = Dir['SafeWalkTests/**/*.swift']
test_files.each do |path|
  file_ref = test_group.new_file(File.basename(path))
  file_ref.path = File.basename(path)
  test_target.add_file_references([file_ref])
end

# ── Link the test target to the main app ─────────────────────────────────────
test_target.add_dependency(main_target)

# ── Copy build settings from main target ─────────────────────────────────────
['Debug', 'Release'].each do |config|
  tc = test_target.build_configuration_list[config]
  tc.build_settings['SWIFT_VERSION']                      = '5.0'
  tc.build_settings['IPHONEOS_DEPLOYMENT_TARGET']         = '16.0'
  tc.build_settings['PRODUCT_BUNDLE_IDENTIFIER']          = 'com.cobsccomp24.safewalk.tests'
  tc.build_settings['TEST_HOST']                          = '$(BUILT_PRODUCTS_DIR)/SafeWalk.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/SafeWalk'
  tc.build_settings['BUNDLE_LOADER']                      = '$(TEST_HOST)'
  tc.build_settings['CODE_SIGN_STYLE']                    = 'Automatic'
  tc.build_settings['GENERATE_INFOPLIST_FILE']            = 'YES'
end

project.save
puts "✅ SafeWalkTests target added to #{project_path}"
