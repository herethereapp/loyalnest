import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app/app.module';
import Consul from 'consul';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const globalPrefix = 'api';
  app.setGlobalPrefix(globalPrefix);

  // Initialize Consul client
  const consul = new Consul({
    host: process.env.CONSUL_URL?.split('//')[1].split(':')[0] || 'consul',
    port: parseInt(process.env.CONSUL_URL?.split(':')[2] || '8500', 10),
  });

  // Define service details
  const serviceName = 'core-service';
  const servicePort = parseInt(process.env.PORT || '3000', 10);
  const serviceAddress = 'core';

  // Register service with Consul
  try {
    await consul.agent.service.register({
      name: serviceName,
      address: serviceAddress,
      port: servicePort,
      check: {
        name: `${serviceName}-health`, // Added required 'name' property
        http: `http://${serviceAddress}:${servicePort}/${globalPrefix}/health`,
        interval: '10s',
        timeout: '5s',
        deregistercriticalserviceafter: '30s',
      },
    });
    Logger.log(`Registered ${serviceName} with Consul at ${serviceAddress}:${servicePort}`);
  } catch (error) {
    Logger.error(`Failed to register ${serviceName} with Consul:`, error);
  }

  // Deregister on shutdown
  process.on('SIGINT', async () => {
    Logger.log(`Deregistering ${serviceName} from Consul`);
    try {
      await consul.agent.service.deregister(serviceName);
    } catch (error) {
      Logger.error(`Failed to deregister ${serviceName}:`, error);
    }
    process.exit(0);
  });

  // Start the NestJS application
  await app.listen(servicePort);
  Logger.log(
    `Application is running on: http://localhost:${servicePort}/${globalPrefix}`,
  );
}

bootstrap();