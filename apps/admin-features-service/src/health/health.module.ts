import { Module } from '@nestjs/common';
import { TerminusModule } from '@nestjs/terminus';
import { HealthController } from './health.controller';
import {
  KafkaHealthIndicator,
  RedisHealthIndicator,
  PostgresHealthIndicator,
} from '@loyalnest/health-check';

@Module({
  imports: [TerminusModule],
  controllers: [HealthController],
  providers: [KafkaHealthIndicator, RedisHealthIndicator, PostgresHealthIndicator],
})
export class HealthModule {}
