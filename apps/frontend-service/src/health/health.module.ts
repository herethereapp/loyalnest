import { Module } from '@nestjs/common';
import { TerminusModule } from '@nestjs/terminus';
import { HealthController } from './health.controller';
import {
  RedisHealthIndicator,
  KafkaHealthIndicator,
  PostgresHealthIndicator,
} from '@loyalnest/health-check';

@Module({
  imports: [TerminusModule],
  controllers: [HealthController],
  providers: [RedisHealthIndicator, KafkaHealthIndicator, PostgresHealthIndicator],
})
export class HealthModule {}
