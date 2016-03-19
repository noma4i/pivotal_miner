require_dependency 'user'

module UserPatch

  def self.included(klass) # :nodoc:
    klass.class_eval do
      unloadable

      def self.get_by_pivotal_id(pivotal_id)
        users ||= User.joins({custom_values: :custom_field}).where("custom_fields.name=? AND custom_values.value=?", 'Pivotal User ID', pivotal_id)

        users.last
      end

      def pivotal_id
        begin
          CustomValue.joins(:custom_field).where(custom_fields: {name: 'Pivotal User ID'}, customized_id: self.id).first
        rescue
          raise "Can't find User's 'Pivital USER_ID' custom field!"
        end
      end
    end
  end

end
