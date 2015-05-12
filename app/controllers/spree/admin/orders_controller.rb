module Spree
  module Admin
    class OrdersController < Spree::Admin::BaseController
      before_action :initialize_order_events
      before_action :load_order, only: [:edit, :update, :cancel, :resume, :approve, :resend, :open_adjustments, :close_adjustments, :cart]

      respond_to :html
      helper_method :getPrice
      helper_method :getPaymentState

      def index
        params[:q] ||= {}
        params[:q][:completed_at_not_null] ||= '1' if Spree::Config[:show_only_complete_orders_by_default]
        @show_only_completed = params[:q][:completed_at_not_null] == '1'
        params[:q][:s] ||= @show_only_completed ? 'completed_at desc' : 'created_at desc'
        params[:q][:completed_at_not_null] = '' unless @show_only_completed

        # As date params are deleted if @show_only_completed, store
        # the original date so we can restore them into the params
        # after the search
        created_at_gt = params[:q][:created_at_gt]
        created_at_lt = params[:q][:created_at_lt]

        params[:q].delete(:inventory_units_shipment_id_null) if params[:q][:inventory_units_shipment_id_null] == "0"

        if params[:q][:created_at_gt].present?
          params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue ""
        end

        if params[:q][:created_at_lt].present?
          params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
        end

        if @show_only_completed
          params[:q][:completed_at_gt] = params[:q].delete(:created_at_gt)
          params[:q][:completed_at_lt] = params[:q].delete(:created_at_lt)
        end

        @search = Order.accessible_by(current_ability, :index).ransack(params[:q])

        # lazyoading other models here (via includes) may result in an invalid query
        # e.g. SELECT  DISTINCT DISTINCT "spree_orders".id, "spree_orders"."created_at" AS alias_0 FROM "spree_orders"
        # see https://github.com/spree/spree/pull/3919
        @orders = @search.result(distinct: true).
          page(params[:page]).
          per(params[:per_page] || Spree::Config[:orders_per_page])

        # Restore dates
        params[:q][:created_at_gt] = created_at_gt
        params[:q][:created_at_lt] = created_at_lt
      end

      def new
        @order = Order.create(order_params)
        redirect_to cart_admin_order_url(@order)
      end

      def edit

        # can_not_transition_without_customer_info

        # unless @order.completed?
        #   @order.refresh_shipment_rates
        # end

        redirect_to cart_admin_order_url(@order)
      end

      def cart

        @dayofweek_text = {:mon => "Monday", :tue => "Tuesday", :wed => "Wednesday", :thu => "Thursday", :fri => "Friday"}

        @dayofweek_items = {:mon => [], :tue => [], :wed => [], :thu => [], :fri => []}

        line_items = @order.line_items;

        line_items.each do |item|
          case item.delivery_date.strftime('%w')
          when "1"
            @dayofweek_items[:mon] << item
            # @dayofweek_items[:mon][:price] += item.total_price
            puts "here"
          when "2"
            @dayofweek_items[:tue] << item
            puts "here"
          when "3"
            @dayofweek_items[:wed] << item
            puts "here"
          when "4"
            @dayofweek_items[:thu] << item
            puts "here"
          when "5" 
            @dayofweek_items[:fri] << item
            puts "here"
          end
        end

        # unless @order.completed?
        #   @order.refresh_shipment_rates
        # end
        # if @order.shipped_shipments.count > 0
        #   redirect_to edit_admin_order_url(@order)
        # end
      end

      def getPrice(dowitems)
        price = 0

        dowitems.each do |item|
          price += item.price * item.quantity
        end

        return price
      end

      def update
        if @order.update_attributes(params[:order]) && @order.line_items.present?
          @order.update!
          unless @order.completed?
            # Jump to next step if order is not completed.
            redirect_to admin_order_customer_path(@order) and return
          end
        else
          @order.errors.add(:line_items, Spree.t('errors.messages.blank')) if @order.line_items.empty?
        end

        render :action => :edit
      end

      def cancel
        @order.canceled_by(try_spree_current_user)
        flash[:success] = Spree.t(:order_canceled)
        redirect_to :back
      end

      def resume
        @order.resume!
        flash[:success] = Spree.t(:order_resumed)
        redirect_to :back
      end

      def approve
        @order.approved_by(try_spree_current_user)
        flash[:success] = Spree.t(:order_approved)
        redirect_to :back
      end

      def resend
        OrderMailer.confirm_email(@order.id, true).deliver
        flash[:success] = Spree.t(:order_email_resent)

        redirect_to :back
      end

      def open_adjustments
        adjustments = @order.all_adjustments.where(state: 'closed')
        adjustments.update_all(state: 'open')
        flash[:success] = Spree.t(:all_adjustments_opened)

        respond_with(@order) { |format| format.html { redirect_to :back } }
      end

      def close_adjustments
        adjustments = @order.all_adjustments.where(state: 'open')
        adjustments.update_all(state: 'closed')
        flash[:success] = Spree.t(:all_adjustments_closed)

        respond_with(@order) { |format| format.html { redirect_to :back } }
      end

      def getPaymentState(payment)
        state = ""
        if payment
          isPay = payment.is_pay

          if isPay
            state = "complete"
          else
            state = "pending"
          end
        end
        return state
      end

      private
        def order_params
          params[:created_by_id] = try_spree_current_user.try(:id)
          params.permit(:created_by_id)
        end

        def load_order
          @order = Order.includes(:adjustments).find_by_number!(params[:id])
          authorize! action, @order
        end

        # Used for extensions which need to provide their own custom event links on the order details view.
        def initialize_order_events
          @order_events = %w{approve cancel resume}
        end

        def model_class
          Spree::Order
        end
    end
  end
end
