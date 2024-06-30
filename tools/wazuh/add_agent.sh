#!/bin/bash

SSH_USERNAME=line6
MANAGER_API_IP=10.0.6.206
MANAGER_AGENT_EVENTS_IP=10.0.6.206
WAZUH_VERSION=4.7.5-1

# Main script logic
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <localhost|IP_ADDRESS>"
  exit 1
fi

TARGET=$1
USER=$(op item get "Wazuh API Creds" --vault "HomeLab K8S" --format json | jq '.fields[1].value' | tr -d '"')
PASSWORD=$(op item get "Wazuh API Creds" --vault "HomeLab K8S" --format json | jq '.fields[2].value' | tr -d '"')

# Generate the script to run
cat <<EOF > /tmp/wazuh_agent_setup.sh
#!/bin/bash

MANAGER_API_IP=$MANAGER_API_IP
MANAGER_AGENT_EVENTS_IP=$MANAGER_AGENT_EVENTS_IP
USER=$USER
PASSWORD=$PASSWORD
WAZUH_VERSION=$WAZUH_VERSION

exit_if_empty() {
  VAR_NAME=\$1
  VAR_VALUE=\$2

  if [ -z "\$VAR_VALUE" ]; then
    echo "Error: \$VAR_NAME is empty or not set."
    exit 1
  fi
}

# Function to generate JWT token
generate_jwt() {
  MANAGER_API_IP=\$1
  USER=\$2
  PASSWORD=\$3

  echo "Generating JWT token..."
  export TOKEN=\$(curl -s -u \$USER:\$PASSWORD -k -X POST "https://\$MANAGER_API_IP:55000/security/user/authenticate?raw=true")
  echo TOKEN=\$TOKEN
  echo ""
}

# Function to request the agent key
request_agent_key() {
  MANAGER_API_IP=\$1
  TOKEN=\$2
  AGENT_NAME=\$3

  echo "Checking if agent \$AGENT_NAME exists..."
  AGENT_ID=\$(curl -s -k -X GET "https://\$MANAGER_API_IP:55000/agents?pretty=true&sort=-ip,name" -H "Authorization: Bearer \$TOKEN" | jq -r ".data.affected_items[] | select(.name == \"\$AGENT_NAME\") | .id")
  echo AGENT_ID=\$AGENT_ID
  echo ""

  if [ -n "\$AGENT_ID" ]; then
    echo "Agent \$AGENT_NAME exists with ID \$AGENT_ID. Deleting agent..."
    DELETED=\$(curl -s -k -X DELETE "https://\$MANAGER_API_IP:55000/agents?pretty=true&older_than=0s&agents_list=\$AGENT_ID&status=all" -H "Authorization: Bearer \$TOKEN" | jq -r ".data.total_affected_items")
    echo "Deleted: \$DELETED"
    echo ""
  else
    echo "Agent \$AGENT_NAME does not exist or is never connected."
    echo ""
  fi

  echo "Creating agent \$AGENT_NAME..."
  export AGENT_KEY=\$(curl -s -k -X POST -d "{\"name\":\"\$AGENT_NAME\"}" "https://\$MANAGER_API_IP:55000/agents?pretty=true" -H "Content-Type:application/json" -H "Authorization: Bearer \$TOKEN" | jq -r '.data.key')
  echo AGENT_KEY=\$AGENT_KEY
  echo ""
}

# Determine agent name based on OS
if [[ "\$OSTYPE" == "darwin"* ]]; then
  AGENT_NAME=\$(hostname)
else
  AGENT_NAME=\$HOSTNAME
fi
echo AGENT_NAME=\$AGENT_NAME
echo ""
exit_if_empty AGENT_NAME \$AGENT_NAME

generate_jwt \$MANAGER_API_IP \$USER \$PASSWORD
exit_if_empty TOKEN \$TOKEN

request_agent_key \$MANAGER_API_IP \$TOKEN \$AGENT_NAME
exit_if_empty AGENT_KEY \$AGENT_KEY

if [[ "\$OSTYPE" == "darwin"* ]]; then
  # Only Apple Silicon supported here. Add logic if you need Intel x64
  echo "Installing Wazuh Agent..."
  wget -q -O /tmp/wazuh-agent.pkg https://packages.wazuh.com/4.x/macos/wazuh-agent-\$WAZUH_VERSION.arm64.pkg
  echo "WAZUH_MANAGER=\"\$MANAGER_AGENT_EVENTS_IP\"" > /tmp/wazuh_envs
  sudo installer -pkg /tmp/wazuh-agent.pkg -target /
  echo ""

  echo "Importing Agent Key..."
  sudo /Library/Ossec/bin/manage_agents -i "\$AGENT_KEY"
  echo ""

  echo "Reloading Wazuh Agent..."
  sudo sed -i.bak "s|<address>.*</address>|<address>\$MANAGER_AGENT_EVENTS_IP</address>|" /Library/Ossec/etc/ossec.conf
  sudo /Library/Ossec/bin/wazuh-control restart
  echo ""
else
  # DEB only here. Add logic if you need RPM
  echo "Installing Wazuh Agent..."
  wget -q -O /tmp/wazuh-agent.deb "https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_\$(echo \$WAZUH_VERSION)_amd64.deb"
  sudo WAZUH_MANAGER=\"\$MANAGER_AGENT_EVENTS_IP\" dpkg -i /tmp/wazuh-agent.deb

  echo "Importing Agent Key..."
  sudo /var/ossec/bin/manage_agents -i "\$AGENT_KEY"
  echo ""

  # Set correct manager IP
  sudo sed -i.bak "s|<address>.*</address>|<address>\$MANAGER_AGENT_EVENTS_IP</address>|" /var/ossec/etc/ossec.conf

  echo "Reloading Wazuh Agent..."
  systemctl daemon-reload
  systemctl enable wazuh-agent
  systemctl restart wazuh-agent
fi
EOF

chmod +x /tmp/wazuh_agent_setup.sh

if [ "$TARGET" == "localhost" ]; then
  # Execute the script locally
  /tmp/wazuh_agent_setup.sh
  rm /tmp/wazuh_agent_setup.sh
else
  # Upload and execute the script on the remote host
  scp /tmp/wazuh_agent_setup.sh $SSH_USERNAME@$TARGET:/tmp/wazuh_agent_setup.sh
  ssh $SSH_USERNAME@$TARGET "sudo /tmp/wazuh_agent_setup.sh && rm /tmp/wazuh_agent_setup.sh"
  rm /tmp/wazuh_agent_setup.sh
fi
