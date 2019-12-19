#!/bin/bash

# make a temporary directory to work in
tmpdir=$(mktemp -d -t watchdog-XXXX)
cd "$tmpdir"

# clone watchdog
git clone https://github.com/sdslabs/watchdog.git
cd watchdog

# compile watchdog
cargo build --release

# build configuration file
config="""
# Hostname of the machine running watchdog. Note that this should be
# same as the file you create in the \`hosts\` directory in keyhouse.
hostname = '$1'

# Keyhouse repository configuration
[keyhouse]

# URL of the Keyhouse repository, it should be of the format
# \`https://api.github.com/repos/<ORGANIZATION>/<KEYHOUSE-REPOSITORY>/contents\`
base_url = 'https://api.github.com/repos/$3/contents'

# This should be a personal access token made by a member of organization on his/her
# behalf who can read the Keyhouse repository. Go to this
# https://github.com/settings/tokens/new?description=Keyhouse%20Token&scopes=repo
# to make a new token with correct scopes.
token = '$2'

# Webhook APIs corresponding to various notifiers
[notifiers]

# Make an incoming hook to your Slack workspace from this
# app(https://slack.com/apps/A0F7XDUAZ-incoming-webhooks)
# and paste the hook URL here. You can customize the icon and name as you like.
slack = '<%=slack%>'

"""

echo "$config" > config.toml

# Install all the files at right place
mkdir -p /opt/watchdog/bin
mkdir -p /opt/watchdog/logs
touch /opt/watchdog/logs/sudo.logs
touch /opt/watchdog/logs/su.logs
touch /opt/watchdog/logs/ssh.logs

cd install

cp ../target/release/watchdog /opt/watchdog/bin/watchdog
chown root /opt/watchdog/bin/watchdog
chgrp root /opt/watchdog/bin/watchdog
chmod  700 /opt/watchdog/bin/watchdog


cp ../config.toml /opt/watchdog/config.toml
chmod 700 /opt/watchdog/config.toml

# edit `sshd_config` file
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.watchdog.bak
python3 edit-sshd-config.py
cp watchdog_tmp_sshd_config /etc/ssh/sshd_config
rm watchdog_tmp_sshd_config
service sshd restart

# installing pam_exec lines
python3 pam-install-sudo.py
python3 pam-install-su.py
python3 pam-install-ssh.py

cp watchdog_tmp_sudo /etc/pam.d/sudo
cp watchdog_tmp_su /etc/pam.d/su
cp watchdog_tmp_ssh /etc/pam.d/sshd

rm watchdog_tmp_sudo
rm watchdog_tmp_su
rm watchdog_tmp_ssh

cd "$tmpdir"
rm -rf watchdog
