#!/bin/bash

while read IP; do
	scp id_rsa user01@$IP:/home/user01/.sh/
done < file.lst	
