#!/bin/sh
#
# asdf
#
# This installs the version management library asdf and some of the plugins

# Check for asdf
if test ! $(which asdf)
then
  echo "  Installing asdf for you."
  brew install asdf > /tmp/asdf-install.log
fi

# Check for ruby plugin
if [[ "$(asdf plugin list)" != *ruby* ]]
then
  echo "  Ruby asdf plugin is being installed"
  asdf plugin add ruby
fi

exit 0
