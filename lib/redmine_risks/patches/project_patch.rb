require_dependency 'project'

module RedmineRisks
  module Patches
    module ProjectPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          
          has_many :risks, :dependent => :destroy
        end
      end

      module InstanceMethods
        # Any instance methods you need
      end
    end
  end
end

unless Project.included_modules.include?(RedmineRisks::Patches::ProjectPatch)
  Project.send(:include, RedmineRisks::Patches::ProjectPatch)
end