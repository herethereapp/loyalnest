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
Service Name	Suggested Port	DB Service Name
--------------           ----------------        ------------------
auth-service		3001	auth-service-db
auth-service-e2e		3101	auth-service-test-db

core-service		3002	core-service-db
core-service-e2e		3102	core-service-test-db

points-service		3003	points-service-db
points-service-e2e		3103	points-service-test-db

referrals-service		3004	referrals-service-db
referrals-service-e2e	3104	referrals-service-test-db

api-gateway		3005	n/a
api-gateway-e2e		3105	n/a

rfm-service		3006	rfm-service-db
rfm-service-e2e		3106	rfm-service-test-db

event_tracking-service	3007	event_tracking-service-db
event_tracking-service-e2e	3107	event_tracking-service-test-db

gamification-service	3008	gamification-service-db
gamification-service-e2e	3108	gamification-service-test-db

admin_core-service		3010	admin_core-service-db
admin_core-service-e2e	3110	admin_core-service-test-db

admin_features-service	3011	admin_features-service-db
admin_features-service-e2e	3111	admin_features-service-test-db

frontend			3020 (default 4173)	 n/a
frontend-e2e		3120	n/a

products-service		3021	products-service-db
products-service-e2e	3121	products-service-test-db

campaign-service		3031	campaign-service-db
campaign-service-e2e	3131	campaign-service-test-db

users-service		3041	users-service-db
users-service-e2e		3141	users-service-test-db

roles-service		3051	roles-service-db
roles-service-e2e		3151	roles-service-test-db


Microservice (Port)				DB Service (Port)					SQL file
-------------------				-----------------					---------
admin_core-service (3010)		admin_core-service-db (5433)		admin_core-service.sql
admin_features-service (3011)  	admin_features-service-db (5434)    admin_features-service.sql
auth-service (3001)				auth-service-db (5435)				auth-service.sql
campaign-service (3031)       	campaign-service-db (5436)			campaign-service.sql
core-service (3002)          	core-service-db (5437) 				core-service.sql
event_tracking-service (3007)   event_tracking-service-db (5438) 	event_tracking-service.sql
gamification-service (3008)     gamification-service-db (5439) 		gamification-service.sql
products-service (3021)         products-service-db (5440) 			products-service.sql
referrals-service (3004)        referrals-service-db (5441) 		referrals-service.sql
rfm-service (3006)       		rfm-service-db (5442) 				rfm-service.sql
roles-service (3051)       	    roles-service-db (5443) 			roles-service.sql
users-service (3041)          	users-service-db (5444) 			users-service.sql
frontend (3020)					N/A									N/A
api-gateway (3005)				N/A									N/A


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