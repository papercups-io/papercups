#!/bin/bash

# set up ses function
cd lambdas/send-email-to-webhook || exit

npm install

# REQUIREMENT TO CREATE A LAMBDA ROLE: See: https://aws.amazon.com/blogs/messaging-and-targeting/forward-incoming-email-to-an-external-destination/

zip -r function.zip .
aws lambda create-function --function-name "send-email-to-webhook" \
    --runtime 'nodejs14.x' \
    --handler "index.handler" \
    --role "arn:aws:iam::$AWS_ACCOUNT_ID:role/lambda-s3-role" \
    --zip-file fileb://function.zip \
    --environment "Variables={WEBHOOK_URL=$SES_WEBHOOK_URL}"

# You may need to add a resource based policy that allows ses to trigger the lambda function from your aws account

rm function.zip
