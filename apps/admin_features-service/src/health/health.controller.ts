import { Controller, Get } from '@nestjs/common';
import { HealthCheckService, HealthCheck } from '@nestjs/terminus';
import {
  KafkaHealthIndicator,
  RedisHealthIndicator,
  PostgresHealthIndicator,
} from '@loyalnest/health-check';

@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private kafkaHealth: KafkaHealthIndicator,
    private redisHealth: RedisHealthIndicator,
    private postgresHealth: PostgresHealthIndicator,
  ) {}

  @Get()
  @HealthCheck()
  check() {
    return this.health.check([
      () => this.postgresHealth.isHealthy('postgres'),
      () => this.redisHealth.isHealthy('redis'),
      () => this.kafkaHealth.isHealthy('kafka'),
    ]);
  }
}
