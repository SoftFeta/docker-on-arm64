apt-get update
apt-get upgrade -y

apt-get install -y adduser iptables init-system-helpers apparmor libapparmor1 libc6 libdevmapper1.02.1 aufs-tools btrfs-tools ca-certificates golang-1.6

if [ -e "/etc/udev/rules.d/z80_docker-engine.rules" ]; then
	rm -f "/etc/udev/rules.d/z80_docker-engine.rules"
fi

# copy all the files into system
cp -rf data/* /

# create docker system group
if ! getent group docker > /dev/null; then
	groupadd --system docker
fi

# run configuration
APP_PROFILE="/etc/apparmor.d/docker-engine"
if [ -f "$APP_PROFILE" ]; then
    # Add the local/ include
    LOCAL_APP_PROFILE="/etc/apparmor.d/local/docker-engine"

    test -e "$LOCAL_APP_PROFILE" || {
        tmp=`mktemp`
    cat <<EOM > "$tmp"
# Site-specific additions and overrides for docker-engine.
# For more details, please see /etc/apparmor.d/local/README.
EOM
        mkdir `dirname "$LOCAL_APP_PROFILE"` 2>/dev/null || true
        mv -f "$tmp" "$LOCAL_APP_PROFILE"
        chmod 644 "$LOCAL_APP_PROFILE"
    }

    # Reload the profile, including any abstraction updates
    if aa-status --enabled 2>/dev/null; then
        apparmor_parser -r -T -W "$APP_PROFILE" || true
    fi
fi

# configure services with systemctl
systemctl unmask docker.service >/dev/null || true

# was-enabled defaults to true, so new installations run enable.
if systemctl --quiet is-enabled docker.service ; then
	# Enables the unit on first installation, creates new
	# symlinks on upgrades if the unit file has changed.
	systemctl enable docker.service >/dev/null || true
else
	# Update the statefile to add new symlinks (if any), which need to be
	# cleaned up on purge. Also remove old symlinks.
	systemctl daemon-reload >/dev/null || true
fi

# This will only remove masks created by d-s-h on package removal.
systemctl unmask docker.socket >/dev/null || true

# was-enabled defaults to true, so new installations run enable.
if systemctl --quiet is-enabled docker.socket; then
	# Enables the unit on first installation, creates new
	# symlinks on upgrades if the unit file has changed.
	systemctl enable docker.socket >/dev/null || true
else
	# Update the statefile to add new symlinks (if any), which need to be
	# cleaned up on purge. Also remove old symlinks.
	systemctl daemon-reload >/dev/null || true
fi

if [ -x "/etc/init.d/docker" ]; then
	update-rc.d docker defaults >/dev/null
	invoke-rc.d docker start || exit $?
fi

if [ -e "/etc/udev/rules.d/z80_docker-engine.rules" ]; then
	echo "Preserving user changes to /etc/udev/rules.d/80-docker-engine.rules ..."
	if [ -e "/etc/udev/rules.d/80-docker-engine.rules" ]; then
		mv -f "/etc/udev/rules.d/80-docker-engine.rules" "/etc/udev/rules.d/80-docker-engine.rules.dpkg-new"
	fi
	mv -f "/etc/udev/rules.d/z80_docker-engine.rules" "/etc/udev/rules.d/80-docker-engine.rules"
fi
