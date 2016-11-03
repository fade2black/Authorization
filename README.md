## Role based authorization module in Rails

#### Introduction
In two of my recent projects I used role based authorization together with Devise gem.There are a lot of gems providing elegant solutions, CanCan and Pundit for example. In this article I want to demonstrate how to implement a module that adds authorization logic to a controller class at action level based on user's role.

Before we start with <code>Authorization</code> module, let's briefly state what we want to implement. Suppose we have a controller <code>ProductController</code> having the following actions: <code>index</code>, <code>show</code>, <code>create</code>, <code>update</code>, <code>destroy</code>. We want admin user to be able to perform all actions, while non-admin user should be able to invoke only <code>index</code> and <code>show</code>. In other words, admin has full control while non-admin may view a list of products and view details of a single product. We might to extend our controller class with the module <code>Authorization</code> and then explicitly declare user permissions

```ruby
class ProductController < ApplicationController
 extend Authorization
 add_authorization :admin, on: [:index, :show, :create, :update, :destroy]
 add_authorization :user, on: [:index, :show]

 before_action :authorize

  #...
  #...

 private
 def authorize
   if unable?(current_user.role.downcase, params[:action])
      render json: {errors: ['Not Authenticated']}, status: :unauthorized
      return
    end
 end

end
```

The controller class, here, is extended with the module <code>Authorization</code>, then we declare user permissions on actions meaning that admin is able to invoke all methods but non-admin user may invoke only <code>index</code> and <code>show</code> methods. However, these declarations do not trigger the real authorization procedure. We must call a method, <code>authorize</code> for example, where we put authorization logic based on the previous declarations.   

#### Authorization Module
We start by creating a test file <code>authorization_test.rb</code>:
```ruby
require 'minitest/autorun'
require "minitest/reporters"
require './authorization.rb'

Minitest::Reporters.use!

class MyController
  extend Authorization
  add_authorization :admin, on:[:index, :show, :create, :update, :destroy]
  add_authorization :user,  on:[:index, :show]
end

class TestAuthorization < Minitest::Test
  def setup
    #Stubbing for user and admin
    user = Struct.new(:role)
    @current_user = user.new(:user)
    @current_admin = user.new(:admin)

    @controller = MyController.new
  end

  def test_admin_permision
    assert(@controller.admin_authorized_on?(:index))
    assert(@controller.admin_authorized_on?(:show))
    assert(@controller.admin_authorized_on?(:create))
    assert(@controller.admin_authorized_on?(:update))
    assert(@controller.admin_authorized_on?(:destroy))
  end

  def test_user_permision
    assert(@controller.user_authorized_on?(:index))
    assert(@controller.user_authorized_on?(:show))
    assert(!@controller.user_authorized_on?(:create))
    assert(!@controller.user_authorized_on?(:update))
    assert(!@controller.user_authorized_on?(:destroy))
  end

  def test_ability
    assert(@controller.able?(@current_admin.role, 'index'))
    assert(@controller.able?(@current_admin.role, :show))
    assert(@controller.able?(@current_admin.role, 'create'))
    assert(@controller.able?(@current_admin.role, :update))
    assert(@controller.able?(@current_admin.role, :destroy))
    assert(@controller.able?(@current_user.role,  :index))
    assert(@controller.able?(@current_user.role,  'show'))
    assert(@controller.unable?(@current_user.role,  'create'))
    assert(@controller.unable?(@current_user.role,  :update))
  end
end
```
In order to pass the test our module should respond to predicates <code>authorized_on?</code>, <code>able?</code>, and <code>unable?</code>.
Basically, what we are doing is create a class level instance variable (a hash) when the host class (our controller) extends itself with the module. This hash stores information about users' permission, which is used by the predicate methods when checking a user's permission.

So, when a host class extends itself the readonly variable <code>authorization</code> becomes an instance variable of the host class. Then we initialize this variable with the empty hash and define an instance method <code>authorization</code> which is used to access the hash from the predicate methods.
```ruby
module Authorization
  def self.extended(host) # host is MyController class
    attr_reader :authorization # access by MyController.authorization
    host.class_eval do
      @authorization = {} # ActiveSupport::HashWithIndifferentAccess.new in a Rails application
      #instance method
      def authorization
        self.class.authorization
      end
    end
  end

#...
#...

end
```
Finally we add to our module <code>add_authorization</code> methods which becomes class method when the host class extends itself with the module. Inside this method we store user permission information in the hash and for each role-action pair create predicate methods. The final version of the module look as following
```ruby
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
```

#### Usage from a Rails application
In order to use this module in a Rails application we might put the file in the <code>lib</code> directory and require it from the application controller file:
```ruby
require 'authorization.rb'
class ApplicationController < ActionController::API
#...
end
```

#### Conclusion
Thus, we have created a simple authorization module which allows us to declare user permissions to control user access to actions within a Rails controller. As a next step we might add to our module a functionality to read permission information from a database.

## Contributing

1. Fork it.
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
