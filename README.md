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
Service Name	Suggested Port
auth-service		3001
core-service		3002
points-service		3003
referrals-service		3004
api-gateway		3005
rfm_analytics-service	3006
event_tracking-service	3007
gamification-service	3008
admin_core-service		3010
admin_features-service	3011
frontend			3020 (default 4173)
products-service		3021
campaign-service		3031

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