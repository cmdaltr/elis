# Ensure bash stops on errors and undefined variables
set -euo pipefail

# Unattended Manager install safety: ensure Salt master variables are never empty
# so-functions writes `master: '$MSRV'` into /etc/salt/minion; empty MSRV causes Salt to crash.
export MSRV="127.0.0.1"
export MSRVIP="127.0.0.1"

cp /home/tester/SecurityOnion/setup/so-whiptail /home/tester/SecurityOnion/setup/so-whiptail.bak
cp so-whiptail.manager /home/tester/SecurityOnion/setup/so-whiptail
chmod +x /home/tester/SecurityOnion/setup/so-whiptail
sudo bash /home/tester/SecurityOnion/setup/so-setup iso