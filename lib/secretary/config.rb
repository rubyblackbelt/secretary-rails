module Secretary
  class Config
    DEFAULTS = {
      :table_name           => "versions",
      :user_class           => "::User",
      :ignored_attributes   => ['id', 'created_at', 'updated_at']
    }

    attr_writer :table_name
    def table_name
      @table_name || DEFAULTS[:table_name]
    end

    attr_writer :user_class
    def user_class
      @user_class || DEFAULTS[:user_class]
    end

    attr_writer :ignored_attributes
    def ignored_attributes
      @ignored_attributes || DEFAULTS[:ignored_attributes]
    end
  end
end
