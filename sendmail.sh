#!/bin/bash

# Desc:a shell script for sending mail with sendmail command
# Author:by Jason.z
# Mail:ccnuzxg@gmail.com
# Date:2014-03-31
# Copyright: Jasonz (http://www.jason-z.com)
# We use mime protocel,you can get more info from http://en.wikipedia.org/wiki/MIME

ret=$(which sendmail)

if [ "$ret" == "" ];then
	yum -y install sendmail
fi 

# set the encode of your mail 
encode="UTF-8" 

# base64 string
# params:$1 string
#        $2 way B/Q
function base64_string()
{
	if [ "$encode" ] && [ "$1" ] && [ "$2" ];then
		echo "=?"$encode"?"$2"?"$(echo $1 | base64)"?="
	fi
}

from=$(base64_string "sender title" "B")
to="recipient1@example.com,recipient2@example.com"
subject=$(base64_string "Your Email Title" "B")
boundary="_Part_189_619193260.1384275896069"
body="Your Content Of Email Body"

declare -a attachments
attachments=("a.pdf" "b.txt")

# get file mimetype by file command
# params:$1 filename
function get_mimetype()
{
	ret=$(which file)

	if [ "$ret" == "" ];then
		yum -y install file
	fi 

	if [ $1 ];then
		echo $(file --mime-type $1 | cut -d: -f2 | sed s/[[:space:]]//g)
	fi

}

# Build headers
{
 
printf '%s\n' "From: $from
To: $to
Subject: $subject
Mime-Version: 1.0
Content-Type: multipart/mixed; boundary=\"$boundary\"
 
--${boundary}
Content-Type: text/plain; charset=\"$encode\"
Content-Transfer-Encoding: 7bit
Content-Disposition: inline

$body
"
 
# now loop over the attachments, guess the type
# and produce the corresponding part, encoded base64
for file in "${attachments[@]}"; do
 
  [ ! -f "$file" ] && echo "Warning: attachment $file not found, skipping" >&2 && continue
 
  mimetype=$(get_mimetype "$file") 
 
  printf '%s\n' "--${boundary}
Content-Type: $mimetype
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename=\"$(base64_string "$file" "Q")\"
"
 
  base64 "$file"
  echo
done
 
# print last boundary with closing --
printf '%s\n' "--${boundary}--"
 
} | sendmail -t -oi   # you can give more arguments here ,like -v to debug
