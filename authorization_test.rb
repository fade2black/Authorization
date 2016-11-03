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
