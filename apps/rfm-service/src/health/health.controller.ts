import { Controller, Get } from '@nestjs/common';
import { HealthCheck, HealthCheckService } from '@nestjs/terminus';
import {
  RedisHealthIndicator,
  KafkaHealthIndicator,
  PostgresHealthIndicator,
} from '@loyalnest/health-check';

@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private redis: RedisHealthIndicator,
    private kafka: KafkaHealthIndicator,
    private postgres: PostgresHealthIndicator,
  ) {}

  @Get()
  @HealthCheck()
  check() {
    return this.health.check([
      () => this.postgres.isHealthy('postgres'),
      () => this.redis.isHealthy('redis'),
      () => this.kafka.isHealthy('kafka'),
    ]);
  }
}
