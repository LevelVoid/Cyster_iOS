require 'xcodeproj'

project_path = 'PCOS_App.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

def ensure_group(parent_group, group_name)
  group = parent_group.groups.find { |g| g.display_name == group_name || g.name == group_name }
  group ||= parent_group.new_group(group_name)
  group
end

main_group = project.main_group.groups.find { |g| g.display_name == 'PCOS_App' || g.name == 'PCOS_App' }
onboarding_group = ensure_group(main_group, 'Onboarding')
managers_group   = ensure_group(onboarding_group, 'Managers')

new_files = [
  'PCOS_App/Onboarding/Managers/TourTipContent.swift',
  'PCOS_App/Onboarding/Managers/TourTipViewController.swift'
]

new_files.each do |path|
  already = managers_group.files.any? { |f| f.path.end_with?(File.basename(path)) }
  unless already
    ref = managers_group.new_reference(path)
    target.add_file_references([ref])
    puts "Added #{File.basename(path)}"
  else
    puts "Already exists: #{File.basename(path)}"
  end
end

project.save
puts "Done."
