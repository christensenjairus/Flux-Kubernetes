https://forum.proxmox.com/threads/nautilus-activating-ceph-dashboard.85961/
```bash
#!/bin/bash

# Function to prompt for password twice and check if they match
prompt_password() {
    while true; do
        # Prompt for the password twice
        read -s -p "Enter password: " password1
        echo
        read -s -p "Re-enter password: " password2
        echo
        
        # Check if the passwords match
        if [ "$password1" == "$password2" ]; then
            echo "Passwords match."
            break
        else
            echo "Passwords do not match. Please try again."
        fi
    done
}

apt install ceph-mgr-dashboard -y # run on all nodes

ceph config set mgr mgr/dashboard/Acropolis/server_addr 0.0.0.0
ceph config set mgr mgr/dashboard/Citadel/server_addr 0.0.0.0
ceph config set mgr mgr/dashboard/Parthenon/server_addr 0.0.0.0

ceph config set mgr mgr/dashboard/Acropolis/server_port 8000
ceph config set mgr mgr/dashboard/Citadel/server_port 8000
ceph config set mgr mgr/dashboard/Parthenon/server_port 8000

ceph mgr module disable dashboard
ceph mgr module enable dashboard
ceph config set mgr mgr/dashboard/ssl false

read -p "Enter username: " username
prompt_password
echo "$password1" > ./password
ceph dashboard ac-user-create $username -i ./password administrator
rm ./password
echo "User $username created successfully."

# run on every host
systemctl restart ceph-mgr@`hostname -s`.service
systemctl status ceph-mgr@`hostname -s`.service
```