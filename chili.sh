#!/bin/bash

# requires environment variables:
# server
# username
# password
# project_id
# repository

# helper
# thanks stackoverflow
# @param text_to_encode
rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER)
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}


# login to chili tracker
# requires environment for
#  - $username
#  - $password
#  - $server
chili_login(){
  mkdir -p chili
  pushd chili > /dev/null
  rm cookie.jar
  unescaped_authenticity_token=$(curl -s -c cookie.jar -b cookie.jar "${server}/login" | grep 'authenticity_token' | sed 's|.*authenticity_token.*value="\([^"]*\)".*|\1|')
  authenticity_token=$(rawurlencode ${unescaped_authenticity_token} )
  post_data="authenticity_token=${authenticity_token}&username=${username}&password=${password}&login=Login+%C2%BB"
  curl -s -c cookie.jar  -b cookie.jar  "${server}/login" \
    -H "Origin: ${server}" -H 'Accept-Encoding: gzip,deflate' -H 'Accept-Language: en-US,en;q=0.8,de;q=0.6' \
    -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.94 Safari/537.36' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
    -H 'Cache-Control: max-age=0' -H "Referer: ${server}/login" \
    -H 'Connection: keep-alive' --data ${post_data} --compressed \
    > /dev/zero
  popd  > /dev/null
}

# get the issues of a list url "complete uri for report"
# @param ticket_url (predefined issue list)
chili_get_tickets(){
  ticket_url=$1
  pushd chili > /dev/null
  curl -s -c cookie.jar -b cookie.jar "${ticket_url}" > release_tickets
  cat release_tickets  | grep 'a href="/issues' | grep -v '<td class="id">\|<th class="checkbox' | sed 's|.*<td class="tracker">\([^<]*\)</td>.*><a href="/issues/\([0-9]*\)">\([^<]*\).*|\1 \2 \3|'
  rm release_tickets
  popd > /dev/null
}

# create a ticket "subject" "description"
# @param subject (text)
# @param description (text)
chili_create_ticket(){

  pushd chili > /dev/null
  unescaped_authenticity_token=$(curl -s -c cookie.jar -b cookie.jar "${repository}/issues/new" | grep 'authenticity_token'|grep 'hidden' | sed 's|.*authenticity_token.*value="\([^"]*\)".*|\1|')
  authenticity_token=$(rawurlencode ${unescaped_authenticity_token} )

  # 1 bug, 2 feature, 3 support
  tracker_id=3

  subject="$1"
  description="$2"
  parent_issue_id=""
  status_id=""
  # 4 normal
  priority_id=4
  start_date=2014-09-29
  assigned_to_id="33"
  category_id=""
  fixed_version_id=""
  due_date=""
  estimated_hours="1"
  done_ratio="50"
  custom_field_values_1=""


  boundary="----WebKitFormBoundarykvrjuJQLWWKvC0qs"
  #
  >create_bre_ticket.data
  printf "%s%s\r\n" "--" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"authenticity_token\"\r\n\r\n%s" "${unescaped_authenticity_token}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"issue[tracker_id]\"\r\n\r\n%d"  "${tracker_id}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"issue[subject]\"\r\n\r\n%s"  "${subject}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"issue[parent_issue_id]\"\r\n\r\n%s"  "${parent_issue_id}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"issue[description]\"\r\n\r\n%s"  "${description}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"issue[status_id]\"\r\n\r\n%d"  "${status_id}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"issue[priority_id]\"\r\n\r\n%d"  "${priority_id}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"issue[assigned_to_id]\"\r\n\r\n%s"  "${assigned_to_id}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"issue[category_id]\"\r\n\r\n%s"  "${category_id}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"issue[fixed_version_id]\"\r\n\r\n%s"  "${fixed_version_id}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"issue[start_date]\"\r\n\r\n%s"  "${start_date}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"issue[due_date]\"\r\n\r\n%s"  "${due_date}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"issue[estimated_hours]\"\r\n\r\n%s"  "${estimated_hours}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"issue[done_ratio]\"\r\n\r\n%d"  "${done_ratio}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"issue[custom_field_values][1]\"\r\n\r\n%s"  "${custom_field_values_1}" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"attachments[1][file]\"; filename=\"\"\r\nContent-Type: application/octet-stream\r\n\r\n\r\n%s" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"attachments[1][description]\"\r\n\r\n\r\n%s" >> create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data
  printf "Content-Disposition: form-data; name=\"commit\"\r\n\r\nCreate\r\n%s" >>create_bre_ticket.data
  printf "\r\n--%s\r\n" ${boundary} >> create_bre_ticket.data

  curl -s -c cookie.jar -b cookie.jar --verbose "${repository}/issues" -H "Referer: ${repository}/issues/new" -H "Origin: ${server}" \
    -H "Content-Type: multipart/form-data; boundary=${boundary}" \
    --data-binary @create_bre_ticket.data \
    --compressed 2>/dev/null \
    > create_bre_ticket.result

  nohttps_server=$(echo ${server} | sed 's|https://|http://|')
  cat create_bre_ticket.result \
    | grep "<a href="${nohttps_server}/issues/" \
    | sed "s|^.*<a href=\"${nohttps_server}/issues/\([0-9]*\).*$|\1|"
  popd > /dev/null
}

# comment a ticket "ticket-id" "comment/note"
# @param ticket-id
# @param note (text)
chili_comment_ticket(){

  pushd chili > /dev/null
  ticket_id=$1
  current_ticket_text=$(curl -s -c cookie.jar -b cookie.jar "${server}/issues/${ticket_id}")
  unescaped_authenticity_token=$(echo "${current_ticket_text}" | grep 'authenticity_token' | grep 'hidden' | sed 's|.*authenticity_token.*value="\([^"]*\)".*|\1|'| grep -v '<a href' | head -n 1)
  authenticity_token=$(rawurlencode ${unescaped_authenticity_token} )

  # 1 bug, 2 feature, 3 support
  tracker_id=3

  notes="$2"
  parent_issue_id=""
  status_id=""
  # 4 normal
  priority_id=4
  start_date=2014-09-29
  assigned_to_id="33"
  category_id=""
  fixed_version_id=""
  due_date=""
  estimated_hours="1"
  done_ratio="50"
  custom_field_values_1=""


  boundary="----WebKitFormBoundarykvrjuJQLWWKvC0qs"
  #
  >comment_bre_data.data
  printf "%s%s\r\n" "--" ${boundary} >> comment_bre_data.data
  printf "Content-Disposition: form-data; name=\"_method\"\r\n\r\nput">> comment_bre_data.data
  printf "\r\n--%s\r\n" ${boundary} >> comment_bre_data.data
  printf "Content-Disposition: form-data; name=\"authenticity_token\"\r\n\r\n%s" "${unescaped_authenticity_token}" >> comment_bre_data.data
  printf "\r\n--%s\r\n" ${boundary} >> comment_bre_data.data
  printf "Content-Disposition: form-data; name=\"issue[notes]\"\r\n\r\n%s"  "${notes}" >> comment_bre_data.data
  printf "\r\n--%s\r\n" ${boundary} >> comment_bre_data.data
  curl -s -c cookie.jar -b cookie.jar --verbose "${server}/issues/${ticket_id}" -H "Referer: ${repository}/issues/new" -H "Origin: ${server}" \
    -H "Content-Type: multipart/form-data; boundary=${boundary}" \
    --data-binary @comment_bre_data.data \
    --compressed 2>/dev/null \
  > comment_bre_data.result

  popd > /dev/null

}

# change ticket state, maps given string-state to state_id
# @param ticket-id
# @param state (text)
chili_change_ticket_state(){

  pushd chili > /dev/null
  ticket_id=$1
  current_ticket_text=$(curl -s -c cookie.jar -b cookie.jar "${server}/issues/${ticket_id}")
  unescaped_authenticity_token=$(echo "${current_ticket_text}" | grep 'authenticity_token'|grep 'hidden' | sed 's|.*authenticity_token.*value="\([^"]*\)".*|\1|'| grep -v '<a href' | head -n 1)
  authenticity_token=$(rawurlencode ${unescaped_authenticity_token} )

  # 1 bug, 2 feature, 3 support
  tracker_id=3
  case $2 in
    "New")
    status_id=1
    ;;
    "Approved")
    status_id=11
    ;;
    "Feedback")
    status_id=4
    ;;
    "In Progress")
    status_id=2
    ;;
    "Resolved")
    status_id=3
    ;;
    "Testing")
    status_id=7
    ;;
    "Review")
    status_id=10
    ;;
    "Release")
    status_id=8
    ;;
    "Rejected")
    status_id=6
    ;;
    "Closed")
    status_id=5
    ;;
    "OnHold")
    status_id=9
    ;;
    *)
    echo "unsupported state $2"
    return
    ;;
  esac

  notes="changed state: $2 ${status_id}"
  parent_issue_id=""
  # 4 normal
  priority_id=4
  start_date=2014-09-29
  assigned_to_id="33"
  category_id=""
  fixed_version_id=""
  due_date=""
  estimated_hours="1"
  done_ratio="50"
  custom_field_values_1=""


  boundary="----WebKitFormBoundarykvrjuJQLWWKvC0qs"
  #
  >comment_bre_data.data
  printf "%s%s\r\n" "--" ${boundary} >> comment_bre_data.data
  printf "Content-Disposition: form-data; name=\"_method\"\r\n\r\nput">> comment_bre_data.data
  printf "\r\n--%s\r\n" ${boundary} >> comment_bre_data.data
  printf "Content-Disposition: form-data; name=\"authenticity_token\"\r\n\r\n%s" "${unescaped_authenticity_token}" >> comment_bre_data.data
  printf "\r\n--%s\r\n" ${boundary} >> comment_bre_data.data
  printf "Content-Disposition: form-data; name=\"issue[status_id]\"\r\n\r\n%d" "${status_id}" >> comment_bre_data.data
  printf "\r\n--%s\r\n" ${boundary} >> comment_bre_data.data
  printf "Content-Disposition: form-data; name=\"issue[notes]\"\r\n\r\n%s"  "${notes}" >> comment_bre_data.data
  printf "\r\n--%s\r\n" ${boundary} >> comment_bre_data.data

  curl -s -c cookie.jar -b cookie.jar --verbose "${server}/issues/${ticket_id}" -H "Referer: ${repository}/issues/new" -H "Origin: ${server}" \
    -H "Content-Type: multipart/form-data; boundary=${boundary}" \
    --data-binary @comment_bre_data.data \
    --compressed \
    2>/dev/null \
    > comment_bre_data.result
  popd > /dev/null
}