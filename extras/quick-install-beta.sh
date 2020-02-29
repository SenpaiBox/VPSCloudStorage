#!/bin/bash
# WARNING! SCRIPT IS EXPERIMENTAL!
# Autosetup of "CloudStorage"

# Install needed packages
packages=('curl' '7z' 'git' 'fuse')
for tool in ${packages[*]}; do
    trash=`hash $tool 2>>errors`
    if [ "$?" -eq 0 ]; then
        packages_tool="$tool"
        break
    fi
done
if [ -z "${packages_tool}" ]; then
    sudo apt update && sudo apt install git curl p7zip-full fuse -y
fi

# Install Rclone
if [ -f "/usr/bin/rclone" ]; then
    curl https://rclone.org/install.sh | sudo bash -s beta
fi
sleep 3

# Install Mergerfs
ID="$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')"
VERSION_CODENAME="$(grep -oP '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '"')"
mergerfs="/tmp/mergerfs.deb"
mergerfs_latest="$(curl -s -o /dev/null -I -w "%{redirect_url}\n" https://github.com/trapexit/mergerfs/releases/latest | grep -oP "[0-9]+(\.[0-9]+)+$")"
url="https://github.com/trapexit/mergerfs/releases/download/$mergerfs_latest/mergerfs_$mergerfs_latest.$ID-${VERSION_CODENAME}_amd64.deb"
if [ -f "/usr/bin/mergerfs" ]; then
    echo "Mergerfs already installed..."
    echo -n "Install/Update anyway (y/n)? "
    read answer
    if [ "$answer" != "${answer#[Yy]}" ]; then
        sudo rm -rf /usr/bin/mergerfs
        sudo curl -fsSL $url -o $mergerfs
        sudo chmod +x $mergerfs
        sudo dpkg -i $mergerfs
    fi
else
    sudo curl -fsSL $url -o $mergerfs
    sudo chmod +x $mergerfs
    sudo dpkg -i $mergerfs
fi
sudo rm $mergerfs
echo "Mergerfs successfully installed"
mergerfs -v
sleep 3

# Install Docker
if [ -x "$(command -v docker)" ]; then
    echo "Docker already installed..."
    echo -n "Run anyway (y/n)? "
    read docker
    if [ "$docker" != "${docker#[Yy]}" ]; then
        curl -fsSL https://get.docker.com -o /mnt/user/cloudstorage/install-scripts/install-docker.sh
        sh /mnt/user/cloudstorage/install-scripts/install-docker.sh
    fi
else
    curl -fsSL https://get.docker.com -o /mnt/user/cloudstorage/install-scripts/install-docker.sh
    sh /mnt/user/cloudstorage/install-scripts/install-docker.sh
fi
sleep 3

# Install Portainer
container="portainer"
if sudo docker ps -a --format '{{.Names}}' | grep -Eq "^${container}\$"; then
    echo "Portainer already installed..."
else
    echo "Installing Portainer..."
    docker volume create portainer_data
    docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
fi
sleep 3

# Install Rclone Scripts
if [ -f "/mnt/user/cloudstorage" ]; then
    echo "Rclone scripts already installed"
    echo -n "Download and replace current scripts (y/n)?"
    read rclonescripts
    if [ "$rclonescripts" != "${rclonescripts#[Yy]}" ]; then
        sudo rm -rf /mnt/user/cloudstorage/rclone
        curl -fsSL https://raw.githubusercontent.com/SenpaiBox/CloudStorage/master/rclone/rclone-mount.sh -o /mnt/user/cloudstorage/rclone/rclone-mount.sh
        curl -fsSL https://raw.githubusercontent.com/SenpaiBox/CloudStorage/master/rclone/rclone-unmount.sh -o /mnt/user/cloudstorage/rclone/rclone-unmount.sh
        curl -fsSL https://raw.githubusercontent.com/SenpaiBox/CloudStorage/master/rclone/rclone-upload.sh -o /mnt/user/cloudstorage/rclone/rclone-upload.sh
        sudo chmod -R +x /mnt/user/cloudstorage/rclone
    else
        exit
    fi
else
    curl -fsSL https://raw.githubusercontent.com/SenpaiBox/CloudStorage/master/rclone/rclone-mount.sh -o /mnt/user/cloudstorage/rclone/rclone-mount.sh
    curl -fsSL https://raw.githubusercontent.com/SenpaiBox/CloudStorage/master/rclone/rclone-unmount.sh -o /mnt/user/cloudstorage/rclone/rclone-unmount.sh
    curl -fsSL https://raw.githubusercontent.com/SenpaiBox/CloudStorage/master/rclone/rclone-upload.sh -o /mnt/user/cloudstorage/rclone/rclone-upload.sh
    sudo chmod -R +x /mnt/user/cloudstorage/rclone
fi

# Create directories and set permissions
mkdir -p /mnt/user & mkdir -p /mnt/user/appdata & mkdir -p /mnt/user/logs
sudo chmod -R +x /mnt/user
echo "Install complete! Now just setup your Rclone Config file and Cronjob!"
exit