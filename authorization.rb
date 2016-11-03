module Authorization
  def self.extended(host)
    attr_reader :authorization

    host.class_eval do
      @authorization = {} #ActiveSupport::HashWithIndifferentAccess.new
      def authorization
        self.class.authorization
      end
    end
  end

  def add_authorization(role, on_actions)
   @authorization[role] = on_actions[:on]

    self.class_eval do
      define_method("#{role}_authorized_on?") do |action|
        authorization[role].include?(action.to_sym) ||
          authorization[role].include?(action)
      end

      define_method(:able?) do |role, action|
        return false unless authorization[role]
        authorization[role].include?(action.to_sym) ||
           authorization[role].include?(action)
      end

      define_method(:unable?) do |role, action|
        return !able?(role, action)
      end
    end
  end
end
