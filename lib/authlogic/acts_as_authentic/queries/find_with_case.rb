# frozen_string_literal: true

module Authlogic
  module ActsAsAuthentic
    module Queries
      # The query used by public-API method `find_by_smart_case_login_field`.
      # @api private
      class FindWithCase
        # Dup ActiveRecord.gem_version before freezing, in case someone
        # else wants to modify it. Freezing modifies an object in place.
        # https://github.com/binarylogic/authlogic/pull/590
        AR_GEM_VERSION = ActiveRecord.gem_version.dup.freeze

        # @api private
        def initialize(model_class, field, value, sensitive)
          @model_class = model_class
          @field = field.to_s
          @value = value
          @sensitive = sensitive
        end

        # @api private
        def execute
          bind(relation).first
        end

        private

          # @api private
          def bind(relation)
            ar_gem_version = Gem::Version.new(ActiveRecord::VERSION::STRING)
            if ar_gem_version >= Gem::Version.new("5")
              bind = ActiveRecord::Relation::QueryAttribute.new(
                @field,
                @value,
                ActiveRecord::Type::Value.new
              )
              @model_class.where(relation, bind)
            else
              @model_class.where(relation)
            end
          end

          # @api private
          def relation
            ar_gem_version = Gem::Version.new(ActiveRecord::VERSION::STRING)
            if !@sensitive
              @model_class.connection.case_insensitive_comparison(
                @model_class.arel_table,
                @field,
                @model_class.columns_hash[@field],
                @value
              )
            elsif ar_gem_version >= Gem::Version.new("5.0")
              @model_class.connection.case_sensitive_comparison(
                @model_class.arel_table,
                @field,
                @model_class.columns_hash[@field],
                @value
              )
            else
              value = @model_class.connection.case_sensitive_modifier(@value, @field)
              @model_class.arel_table[@field].eq(value)
            end
          end
      end
    end
  end
end
