# frozen_string_literal: true

class CreateRolePermissions < ActiveRecord::Migration[5.2]
  def change
    Role.all.each do |role|
      role.role_permissions.create(name: "can_create_rooms", value: role.can_create_rooms.to_s, enabled: true)
      role.role_permissions.create(name: "send_promoted_email", value: role.send_promoted_email.to_s, enabled: true)
      role.role_permissions.create(name: "send_demoted_email", value: role.send_demoted_email.to_s, enabled: true)
      role.role_permissions.create(name: "can_edit_site_settings", value: role.can_edit_site_settings.to_s,
        enabled: true)
      role.role_permissions.create(name: "can_edit_roles", value: role.can_edit_roles.to_s, enabled: true)
      role.role_permissions.create(name: "can_manage_users", value: role.can_manage_users.to_s, enabled: true)
    end

    # Add these back in once the change to postgres is made
    # remove_column :roles, :can_create_rooms
    # remove_column :roles, :send_promoted_email
    # remove_column :roles, :send_demoted_email
    # remove_column :roles, :can_edit_site_settings
    # remove_column :roles, :can_edit_roles
    # remove_column :roles, :can_manage_users
  end
end
