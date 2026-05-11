require 'xcodeproj'

project_path = 'PCOS_App.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Helper to find or create group
def ensure_group(parent_group, group_name)
  group = parent_group.groups.find { |g| g.display_name == group_name || g.name == group_name }
  if group.nil?
    group = parent_group.new_group(group_name)
  end
  group
end

# Main app group
main_group = project.main_group.groups.find { |g| g.display_name == 'PCOS_App' || g.name == 'PCOS_App' }
unless main_group
  main_group = project.main_group.new_group('PCOS_App')
end

onboarding_group = ensure_group(main_group, 'Onboarding')
managers_group = ensure_group(onboarding_group, 'Managers')
models_group = ensure_group(onboarding_group, 'Models')
controllers_group = ensure_group(onboarding_group, 'Controllers')

files_to_add = [
  { group: managers_group, path: 'PCOS_App/Onboarding/Managers/OnboardingManager.swift' },
  { group: models_group, path: 'PCOS_App/Onboarding/Models/OnboardingPage.swift' },
  { group: controllers_group, path: 'PCOS_App/Onboarding/Controllers/OnboardingPageViewController.swift' },
  { group: controllers_group, path: 'PCOS_App/Onboarding/Controllers/OnboardingContainerViewController.swift' }
]

files_to_add.each do |file_info|
  file_ref = file_info[:group].new_reference(file_info[:path])
  target.add_file_references([file_ref])
end

project.save
puts "Successfully added Onboarding files to Xcode project."
