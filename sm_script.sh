#!/bin/bash

# Set Okta API token and domain
OKTA_API_TOKEN="$OKTA_API_TOKEN"
OKTA_DOMAIN="$OKTA_DOMAIN"

# Set Zendesk API token and domain
ZENDESK_API_TOKEN="$ZENDESK_API_TOKEN"
ZENDESK_DOMAIN="$ZENDESK_DOMAIN"

# Set email parameters
EMAIL_RECIPIENT="recipient@example.com"
EMAIL_SUBJECT="Okta and Zendesk Dashboard"
EMAIL_BODY="Please find attached the Okta and Zendesk dashboard."

# Okta API requests
okta_api_request() {
  local endpoint=$1
  curl -sS \
    -H "Authorization: SSWS $OKTA_API_TOKEN" \
    -H "Accept: application/json" \
    "https://$OKTA_DOMAIN$endpoint"
}

# Zendesk API requests
zendesk_api_request() {
  local endpoint=$1
  curl -sS \
    -u "$ZENDESK_API_TOKEN:X" \
    -H "Accept: application/json" \
    "https://$ZENDESK_DOMAIN$endpoint"
}

# Retrieve number of users from Okta
users_response=$(okta_api_request "/api/v1/users?limit=1")
total_users=$(echo "$users_response" | grep -o '"total": [0-9]*' | grep -o '[0-9]*')

echo "Total Users: $total_users"

# Retrieve number of apps from Okta
apps_response=$(okta_api_request "/api/v1/apps")
total_apps=$(echo "$apps_response" | grep -o '"total": [0-9]*' | grep -o '[0-9]*')

echo "Total Apps: $total_apps"

# Retrieve count of users using each app from Okta
echo "User Counts by App:"
user_counts=""
app_names=$(echo "$apps_response" | grep -o '"name": "[^"]*"' | grep -o '[^"]*')
app_ids=$(echo "$apps_response" | grep -o '"id": "[^"]*"' | grep -o '[^"]*')
IFS=$'\n' read -r -a app_name_array <<< "$app_names"
IFS=$'\n' read -r -a app_id_array <<< "$app_ids"

for ((i = 0; i < ${#app_name_array[@]}; i++)); do
  app_name="${app_name_array[$i]}"
  app_id="${app_id_array[$i]}"

  users_for_app_response=$(okta_api_request "/api/v1/apps/$app_id/users")
  users_for_app_count=$(echo "$users_for_app_response" | grep -o '"total": [0-9]*' | grep -o '[0-9]*')

  echo "App: $app_name"
  echo "Users: $users_for_app_count"
  echo

  user_counts+="App: $app_name\nUsers: $users_for_app_count\n\n"
done

# Export Zendesk dashboard
dashboard_id="123456"  # Replace with actual dashboard ID

dashboard_response=$(zendesk_api_request "/api/v2/dashboard/dashboards/$dashboard_id.json")
dashboard_url=$(echo "$dashboard_response" | grep -o '"url": "[^"]*"' | grep -o '[^"]*')

echo "Zendesk Dashboard URL: $dashboard_url"

# Send email with Okta and Zendesk data
email_content="Total Users in Okta: $total_users\n\nTotal Apps in Okta: $total_apps\n\nUser Counts by App in Okta:\n$user_counts\nZendesk Dashboard URL: $dashboard_url\n"

echo -e "$email_content" | mail -s "$EMAIL_SUBJECT" -a "From: sender@example.com" "$EMAIL_RECIPIENT"
echo "Email sent successfully."

# TO DO - Pingdom API calls
# Dockerise
# Yammer API and auto publish
