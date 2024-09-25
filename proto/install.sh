#!/bin/sh
#
# asdf
#
# This installs the version management library asdf and some of the plugins

# Check for asdf
if test ! $(which proto)
then
  echo "  Installing proto for you."
  curl -fsSL https://moonrepo.dev/install/proto.sh | bash > /tmp/proto-install.log
fi

# Check for nodejs plugin
if [[ "$(proto list node)" == *"No versions installed"* ]]
then
  echo "  Nodejs proto plugin is being installed"
  proto install node
fi

# Check for pnpm plugin
if [[ "$(proto list pnpm)" == *"No versions installed"* ]]
then
  echo "  Pnpm proto plugin is being installed"
  proto install pnpm
fi

# Check for yarn plugin
if [[ "$(proto list yarn)" == *"No versions installed"* ]]
then
  echo "  Yarn proto plugin is being installed"
  proto install yarn
fi

# Check for moon plugin
if [[ "$(proto list moon)" == *"proto::tool::unknown"* ]]
then
  echo "  Moon proto plugin is being added"
  proto plugin add moon "https://raw.githubusercontent.com/moonrepo/moon/master/proto-plugin.toml"
fi

# Check for moon plugin
if [[ "$(proto list moon)" == *"No versions installed"* ]]
then
  echo "  Moon proto plugin is being installed"
  proto install moon
fi

exit 0
