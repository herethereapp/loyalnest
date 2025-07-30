# LoyalNest

====================================
How to generate NestJS services using tsc only, avoiding 
Webpack and preventing @nx/webpack/plugin from 
being re-inserted into nx.json.
(2025/07/21)
====================================
Step 1: Use the official generator, run command as below to generate your NestJS service:

````
npx nx g @nx/nest:application --name=admin_features-service --directory=apps/admin_features-service

√ Which linter would you like to use? · eslint
√ Which unit test runner would you like to use? · jest

````
Step 2: Remove Webpack plugin if it comes back:

Open nx.json, delete this block if added:

````
{
  "plugin": "@nx/webpack/plugin",
  "options": {
    "buildTargetName": "build",
    "serveTargetName": "serve",
    ...
  }
}

````
Step: 3: Delete webpack.config.js in new created service:

````
rm apps/api-gateway/webpack.config.js

````

Step 4: Reset nx to clear cache:

````
npx nx reset

````

Step 5: Repeat above steps to generate other NestJS services we need (one service per time):

````
npx nx g @nx/nest:application --name=auth-service --directory=apps/auth-service
npx nx g @nx/nest:application --name=campaign-service --directory=apps/campaign-service
npx nx g @nx/nest:application --name=core-service --directory=apps/core-service
npx nx g @nx/nest:application --name=event_tracking-service --directory=apps/event_tracking-service
npx nx g @nx/nest:application --name=gamification-service --directory=apps/gamification-service
npx nx g @nx/nest:application --name=api-gateway --directory=apps/api-gateway
npx nx g @nx/nest:application --name=points-service --directory=apps/points-service
npx nx g @nx/nest:application --name=referrals-service --directory=apps/referrals-service
npx nx g @nx/nest:application --name=rfm_analytics-service --directory=apps/rfm_analytics-service
npx nx g @nx/nest:application --name=products-service --directory=apps/products-service
npx nx g @nx/nest:application --name=frontend --directory=apps/frontend
npx nx g @nx/nest:application --name=admin_core-service --directory=apps/admin_core-service

````

=============
Port for each service
(2025/07/21)
=============
Service Name	Suggested Port	DB Name
auth-service		3001	auth_service_db
auth-service-e2e		3101	auth_service_test_db

core-service		3002	core_service_db
core-service-e2e		3102	core_service_test_db

points-service		3003	points_service_db
points-service-e2e		3103	points_service_test_db

referrals-service		3004	referrals_service_db
referrals-service-e2e	3104	referrals_service_test_db

api-gateway		3005	api_gateway_db
api-gateway-e2e		3105	api_gateway_test_db

rfm-service		3006	rfm_service_db
rfm-service-e2e		3106	rfm_service_test_db

event_tracking-service	3007	event_tracking_service_db
event_tracking-service-e2e	3107	event_tracking_service_test_db

gamification-service	3008	gamification_service_db
gamification-service-e2e	3108	gamification_service_test_db

admin_core-service		3010	admin_core_service_db
admin_core-service-e2e	3110	admin_core_service_test_db

admin_features-service	3011	admin_features_service_db
admin_features-service-e2e	3111	admin_features_service_test_db

frontend			3020 (default 4173)	 N/A
frontend-e2e		3120	N/A

products-service		3021	products_service_db
products-service-e2e	3121	products_service_test_db

campaign-service		3031	campaign_service_db
campaign-service-e2e	3131	campaign_service_test_db

users-service		3041	users_service_db
users-service-e2e		3141	users_service_test_db

roles-service		3051	roles_service_db
roles-service-e2e		3151	roles_service_test_db


===============
to do
===============
update project documents by adding:
core-service
frontend
products-service

npx nx build core-service
npx nx serve core-service
npx nx test core-service