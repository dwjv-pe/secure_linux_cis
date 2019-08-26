# frozen_string_literal: true

# local_users.rb
# This fact contains a dictionary of local users and their value for max number of days between a password change
Facter.add(:local_users) do
  confine osfamily: 'RedHat'
  require 'date'
  setcode do
    local_users = {}
    user_list = Facter::Core::Execution.exec('egrep ^[^:]+:[^\!*] /etc/shadow | cut -d: -f1').split("\n")
    user_list.each do |user|
      local_users[user] = {}

      # parse chage output for each user in /etc/shadow and create variables
      last_password_change   = %r{:\s*\K.*}.match(Facter::Core::Execution.exec("chage --list #{user} | grep \"Last password\"")).to_s
      password_expires       = %r{:\s*\K.*}.match(Facter::Core::Execution.exec("chage --list #{user} | grep \"Password expires\"")).to_s
      password_inactive      = %r{:\s*\K.*}.match(Facter::Core::Execution.exec("chage --list #{user} | grep \"Password inactive\"")).to_s
      account_expires        = %r{:\s*\K.*}.match(Facter::Core::Execution.exec("chage --list #{user} | grep \"Account expires\"")).to_s
      minimum_number_of_days = %r{:\d*\K.*}.match(Facter::Core::Execution.exec("chage --list #{user} | grep \"Minimum\""))[0].to_i
      maximum_number_of_days = %r{:\d*\K.*}.match(Facter::Core::Execution.exec("chage --list #{user} | grep \"Maximum\""))[0].to_i
      warning_number_of_days = %r{:\d*\K.*}.match(Facter::Core::Execution.exec("chage --list #{user} | grep \"warning\""))[0].to_i

      # set default values for facts
      last_password_change_days = last_password_change
      password_expires_days     = password_expires
      password_inactive_days    = password_inactive

      # check if password attribute not 'never', then determine days between now and then
      # and check if password is set prior to current date
      if last_password_change    != 'never'
        last_password_change_days = (Date.today - Date.parse(last_password_change)).to_i
        password_date_valid       = Date.parse(last_password_change) <= Date.today
      end

      if password_expires       != 'never'
        password_expires_days    = (Date.parse(password_expires) - Date.today).to_i
        if password_inactive    != 'never'
          password_inactive_days = (Date.parse(password_inactive) - Date.parse(password_expires)).to_i
        end
      end

      if account_expires    != 'never'
        account_expires_days = (Date.parse(account_expires) - Date.today).to_i
      else
        account_expires_days = account_expires
      end

      # create nested fact
      local_users[user] = {
        'last_password_change_days'         => last_password_change_days,
        'password_expires_days'             => password_expires_days,
        'password_inactive_days'            => password_inactive_days,
        'account_expires_days'              => account_expires_days,
        'min_days_between_password_change'  => minimum_number_of_days,
        'max_days_between_password_change'  => maximum_number_of_days,
        'warn_days_between_password_change' => warning_number_of_days,
        'password_date_valid'               => password_date_valid,
      }
    end
    local_users
  end
end
