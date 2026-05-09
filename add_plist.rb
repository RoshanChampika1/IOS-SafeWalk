require 'xcodeproj'

project_path = '/Users/COBSCCOMP242P-064/dev/SafeWalk/SafeWalk.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Check if Resources group exists
resources_group = project.main_group.children.find { |g| g.display_name == 'Resources' || g.name == 'Resources' }
unless resources_group
  resources_group = project.main_group.new_group('Resources', 'SafeWalk/Resources')
end

# Check if file is already in group
file_ref = resources_group.files.find { |f| f.path == 'GoogleService-Info.plist' }
unless file_ref
  file_ref = resources_group.new_file('GoogleService-Info.plist')
end

# Check if file is in Resources build phase
build_phase = target.resources_build_phase
unless build_phase.files_references.include?(file_ref)
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.file_ref = file_ref
  build_phase.files << build_file
end

project.save
