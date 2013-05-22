module RSolr::Ext
  module Notifications
    def self.included(base)
      base.send :extend, ClassMethods
    end

    def execute_with_notifications(*args)
      payload = args.first.dup
      ActiveSupport::Notifications.instrument("execute.rsolr_client", payload) do
         execute_without_notifications(*args)
      end
    end

    module ClassMethods
      def enable_notifications!
        self.class_exec do
          unless method_defined?(:execute_without_notifications)
            alias_method :execute_without_notifications, :execute
            alias_method :execute, :execute_with_notifications
          end
        end
      end
    end
  end
end

