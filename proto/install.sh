#!/bin/sh
#
# proto
#
# This installs the version management library proto and some of the tools

# Check for proto
if test ! $(which proto)
then
  echo "  Installing proto for you."
  curl -fsSL https://moonrepo.dev/install/proto.sh | bash > /tmp/proto-install.log
fi

# Check for nodejs plugin
if [[ "$(proto tool list node 2>&1)" == *"No versions installed"* ]]
then
  echo "  Nodejs proto plugin is being installed"
  proto install node
fi

# Check for pnpm plugin
if [[ "$(proto tool list pnpm 2>&1)" == *"No versions installed"* ]]
then
  echo "  Pnpm proto plugin is being installed"
  proto install pnpm
fi

# Check for yarn plugin
if [[ "$(proto tool list yarn 2>&1)" == *"No versions installed"* ]]
then
  echo "  Yarn proto plugin is being installed"
  proto install yarn
fi

# Check for moon plugin
if [[ "$(proto tool list moon 2>&1)" == *"proto::tool::unknown"* ]]
then
  echo "  Moon proto plugin is being added"
  proto plugin add moon "https://raw.githubusercontent.com/moonrepo/moon/master/proto-plugin.toml"
fi

# Check for moon plugin
if [[ "$(proto tool list moon 2>&1)" == *"No versions installed"* ]]
then
  echo "  Moon proto plugin is being installed"
  proto install moon
fi

exit 0
