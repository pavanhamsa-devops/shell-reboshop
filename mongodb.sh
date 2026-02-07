#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then  
    echo -e "$2... $R FAILURE $N" | tee -a $LOGS_FILE
    exit 1
    else
        echo -e "$2...$R SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongo repo"

dnf install mongodb-org -y 
VALIDATE $? "Installing mongoDB Server"

systemctl enable mongod 
VALIDATE $? "Enabled mongoDB"

systemctl start mongod 
VALIDATE $? "Started mongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "allowing remote connections too"

systemctl restart mongod
VALIDATE $? "Restarted mongoDB"