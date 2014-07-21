require 'stripe'

module Aptible
  module Auth
    class Organization < Resource
      has_many :roles
      has_many :users

      field :id
      field :name
      field :handle
      field :created_at, type: Time
      field :updated_at, type: Time
      field :primary_phone
      field :emergency_phone
      field :city
      field :state
      field :zip
      field :address
      field :stripe_customer_id

      def stripe_customer
        return if stripe_customer_id.nil?
        @stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_id)
      end

      def can_manage_compliance?
        accounts.map(&:type).include? 'production'
      end

      def billing_contact
        return nil unless stripe_customer.metadata['billing_contact']

        @billing_contact ||=
        User.find_by_url(
          stripe_customer.metadata['billing_contact'],
          token: token)
      end

      def security_officer
        # REVIEW: Examine underlying data model for a less arbitrary solution
        security_officers_role = roles.find do |role|
          role.name == 'Security Officers'
        end
        security_officers_role.users.first if security_officers_role
      end

      def accounts
        require 'aptible/api'

        accounts = Aptible::Api::Account.all(token: token, headers: headers)
        accounts.select do |account|
          (link = account.links[:organization]) && link.href == href
        end
      end
    end
  end
end
