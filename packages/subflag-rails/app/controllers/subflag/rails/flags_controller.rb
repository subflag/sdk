# frozen_string_literal: true

module Subflag
  module Rails
    class FlagsController < ApplicationController
      before_action :set_flag, only: %i[show edit update destroy toggle test]

      def index
        @flags = Flag.order(:key)
      end

      def show; end

      def new
        @flag = Flag.new(enabled: true, value_type: "boolean", value: "false")
      end

      def create
        @flag = Flag.new(flag_params)
        if @flag.save
          redirect_to flags_path, notice: "Flag created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit; end

      def update
        if @flag.update(flag_params)
          redirect_to edit_flag_path(@flag), notice: "Flag updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @flag.destroy
        redirect_to flags_path, notice: "Flag deleted."
      end

      def toggle
        @flag.update!(enabled: !@flag.enabled)
        redirect_to flags_path, notice: "Flag #{@flag.enabled? ? 'enabled' : 'disabled'}."
      end

      def test
        context = parse_test_context(params[:context])
        @test_result = @flag.evaluate(context: context)
        @test_context = context

        respond_to do |format|
          format.html { render :edit }
          format.json { render json: { result: @test_result, context: @test_context } }
        end
      end

      private

      def set_flag
        @flag = Flag.find(params[:id])
      end

      def flag_params
        params.require(:flag).permit(:key, :value, :value_type, :enabled, :description).tap do |p|
          if params[:flag][:targeting_rules].present?
            p[:targeting_rules] = JSON.parse(params[:flag][:targeting_rules])
          else
            p[:targeting_rules] = []
          end
        end
      rescue JSON::ParserError
        params.require(:flag).permit(:key, :value, :value_type, :enabled, :description, :targeting_rules)
      end

      def parse_test_context(context_json)
        return {} if context_json.blank?

        JSON.parse(context_json).transform_keys(&:to_sym)
      rescue JSON::ParserError
        {}
      end
    end
  end
end
