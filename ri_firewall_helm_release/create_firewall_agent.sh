crime () {
        eval $($(git rev-parse --show-toplevel)/deployments/tools/aws/manage_cluster.sh ${1} ${2})
}

control_plane_cluster_name=${1#rime-}
control_plane_namespace=$2
control_plane_domain=$3
firewall_agent_info_file=$4

# Switch to correct Kubernetes context
echo "Creating firewall agent for $control_plane_cluster_name/$control_plane_namespace"
crime $control_plane_cluster_name $control_plane_namespace

# Set up auth server tunnel
kubectl -n $control_plane_namespace port-forward service/rime-$control_plane_namespace-auth-server 15017:15017 &
port_forward_pid=$!
sleep 5

# Generate API key
api_token=$(curl --insecure -H "x-rime-user: 77968d5d-2099-40c8-aa28-9c01e8407f2c" -d "{\"name\": \"${control_plane_cluster_name}/${control_plane_namespace} firewall agent setup_$(date +%Y%m%d%H%M)\"}" -X POST https://localhost:15017/v1/users/api-tokens | jq ".fullApiToken" | tr -d '"')

create_agent_response=$(curl -X POST -H "rime-api-key: $api_token" -d "{\"name\": \"${control_plane_cluster_name}/${control_plane_namespace} firewall agent_$(date +%Y%m%d%H%M)\"}" $control_plane_domain/v1-beta/agents/firewall)
agent_id=$(echo $create_agent_response | jq ".agentId.uuid" | tr -d '"')
agent_api_token=$(echo $create_agent_response | jq ".apiToken" | tr -d '"')
kill $port_forward_pid

# Return agent_id and agent_api_token
echo "riFirewall:\n  registerFirewallAgent:\n    agentID: \"$agent_id\"\n    apiKey: \"$agent_api_token\"" > $firewall_agent_info_file
