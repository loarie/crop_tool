class Report < ActiveRecord::Base
  include ::CropModule::Maths
  #require Rails.root.join('lib/crop_module')
end
