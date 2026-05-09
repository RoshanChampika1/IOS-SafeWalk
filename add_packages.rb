require 'xcodeproj'

project_path = '/Users/COBSCCOMP242P-064/dev/SafeWalk/SafeWalk.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Check if GoogleSignIn package is already added
google_pkg = project.root_object.package_references.find { |pkg| pkg.repositoryURL.include?('GoogleSignIn') }
unless google_pkg
  google_pkg = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  google_pkg.repositoryURL = 'https://github.com/google/GoogleSignIn-iOS.git'
  google_pkg.requirement = {
    'kind' => 'upToNextMajorVersion',
    'minimumVersion' => '7.1.0'
  }
  project.root_object.package_references << google_pkg
end

# Check if firebase-ios-sdk is added
firebase_pkg = project.root_object.package_references.find { |pkg| pkg.repositoryURL.include?('firebase-ios-sdk') }

def add_product(project, target, package, product_name)
  product_ref = project.frameworks_group.children.find { |c| c.isa == 'XCSwiftPackageProductDependency' && c.product_name == product_name }
  unless product_ref
    product_ref = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    product_ref.product_name = product_name
    product_ref.package = package
  end

  build_file = target.frameworks_build_phase.files.find { |f| f.product_ref == product_ref }
  unless build_file
    build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
    build_file.product_ref = product_ref
    target.frameworks_build_phase.files << build_file
  end
end

add_product(project, target, firebase_pkg, 'FirebaseAuth')
add_product(project, target, google_pkg, 'GoogleSignIn')

project.save
