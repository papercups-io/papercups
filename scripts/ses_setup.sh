#!/bin/bash

# set up ses function
cd lambda-send-email-to-webhook || exit

npm install

# REQUIREMENT TO CREATE A LAMBDA ROLE: See: https://aws.amazon.com/blogs/messaging-and-targeting/forward-incoming-email-to-an-external-destination/

zip -r function.zip .
aws lambda create-function --function-name "send-email-to-webhook-kam" \
    --runtime 'nodejs14.x' \
    --handler "email-arrived-alert.handler" \
    --role "arn:aws:iam::775327867774:role/lambda-s3-role" \
    --zip-file fileb://function.zip \
    --environment "Variables={WEBHOOK_URL=http://df15-184-152-2-44.ngrok.io}" \
    --handler "email-arrived-alert.handler"

# You may need to add a resource based policy that allows ses to trigger the lambda function from your aws account

rm function.zip
