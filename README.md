### BG Monitor

A Flutter project for entering and tracking blood glucose levels.

This project integrates with Amazon Web Services:
- Cognito - provides user management (sign up, login, password reset)
- Lambda - logs BG values to dynamodb, sends SMS messages to receivers
- DynamoDB - provides storage (via Lambda) and retrieval (via API Gateway) of BG values


If interested in more details on setting up, please contact me.
