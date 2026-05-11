require 'xcodeproj'

project_path = 'PCOS_App.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

def ensure_group(parent_group, group_name)
  group = parent_group.groups.find { |g| g.display_name == group_name || g.name == group_name }
  if group.nil?
    group = parent_group.new_group(group_name)
  end
  group
end

main_group = project.main_group.groups.find { |g| g.display_name == 'PCOS_App' || g.name == 'PCOS_App' }
home_group = ensure_group(main_group, 'Home')
models_group = ensure_group(home_group, 'Model')

file_ref = models_group.new_reference('PCOS_App/Home/Model/WellnessTips.swift')
target.add_file_references([file_ref])

project.save
puts "Successfully added WellnessTips.swift to Xcode project."
