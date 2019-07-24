# Description: Error handling method to just notify as it's too early to do anything
#
# Write an entry to the logfile template
$evm.log(:info, "BHP: Backing out clean up playbook")

# Send notifications
$evm.create_notification(:type => :automate_user_error, :message => "Provisioning error. Please contact your administrator")
