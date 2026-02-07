#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.hamsa.sbs

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

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabled default nodejs version"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabled 20version nodejs"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing nodejs Server"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "roboshop user already exist... $Y Skipping $N"
fi

mkdir -p /app 
VALIDATE $? "Creating directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading code"

cd /app 
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "Unzip catalogue code"

npm install &>>$LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
systemctl enable catalogue &>>$LOGS_FILE
systemctl start catalogue
VALIDATE $? "Started and enalbled catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y

INDEX=$(mongosh --host $MONGODB_HOST --quiet --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js
    VALIDATE $? "Loading Products"
else
    echo -e "Products already loaded"