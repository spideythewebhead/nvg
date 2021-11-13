does_command_exists () {
  command -v "$1" 1> /dev/null
}

if does_command_exists fvm ; then
  echo "FVM detected"

  fvm flutter build linux
elif does_command_exists flutter ; then
  echo "Flutter detected"
  flutter build linux
else
  echo "FVM or Flutter were not detected.. exiting script"
  exit 1
fi

sleep 2

mkdir -p $HOME/nvg
cp -r build/linux/x64/release/bundle/* $HOME/nvg