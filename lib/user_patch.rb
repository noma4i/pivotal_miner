require_dependency 'user'

module UserPatch

  def self.included(klass) # :nodoc:
    klass.class_eval do
      unloadable

      def self.get_by_pivotal_id(pivotal_id)
        users ||= User.joins({custom_values: :custom_field}).where("custom_fields.name=? AND custom_values.value=?", PivotalMiner::CF_USER_ID, pivotal_id)

        users.last
      end

      def pivotal_custom_value(name)
        custom_value = CustomValue.joins(:custom_field).where(custom_fields: {name: name}, customized_id: self.id).first rescue nil
        if !custom_value.present?
          CustomValue.create!(
            customized_type: 'Principal',
            custom_field_id: CustomField.find_by_name(PivotalMiner::CF_USER_ID).id,
            customized_id: self.id,
            value: nil
          )
          pivotal_custom_value(name)
        else
          custom_value
        end
      end

      def pivotal_id
        begin
          CustomValue.joins(:custom_field).where(custom_fields: {name: PivotalMiner::CF_USER_ID}, customized_id: self.id).first
        rescue
          raise "Can't find User's 'Pivital USER_ID' custom field!"
        end
      end

      def pivotal_id=(pivotal_id)
        pivotal_custom_value(PivotalMiner::CF_USER_ID).update_column(:value, pivotal_id.to_s)
      end
    end
  end

end


CustomValue.joins(:custom_field).where(custom_fields: {name: PivotalMiner::CF_USER_ID}, customized_id: 1)
