require 'stripe'
require 'aptible/billforward'

module Aptible
  module Auth
    class Organization < Resource
      has_many :roles
      has_many :users
      has_many :invitations
      belongs_to :security_officer
      belongs_to :billing_contact

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
      field :stripe_subscription_id
      field :stripe_subscription_status
      field :plan
      field :security_alert_email
      field :ops_alert_email
      field :security_officer_id
      field :billing_contact_id
      field :billforward_account_id

      def billforward_account
        return nil if billforward_account_id.nil?
        @billforward_account ||= Aptible::BillForward::Account.find(
          billforward_account_id
        )
      end

      def stripe_customer
        return nil if stripe_customer_id.nil?
        @stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_id)
      end

      def can_manage_compliance?
        %w(production pilot).include?(plan)
      end

      def subscription
        return nil if stripe_subscription_id.nil?
        subscriptions = stripe_customer.subscriptions
        @subscription ||= subscriptions.retrieve(stripe_subscription_id)
      end

      def subscribed?
        !!stripe_subscription_id
      end

      def privileged_roles
        roles.select(&:privileged?)
      end

      def accounts
        return @accounts if @accounts
        require 'aptible/api'

        accounts = Aptible::Api::Account.all(token: token, headers: headers)
        @accounts = accounts.select do |account|
          (link = account.links[:organization]) && link.href == href
        end
      end
    end
  end
end
