// libs/health-check/postgres.health.ts
import { Injectable } from '@nestjs/common';
import { HealthIndicator, HealthIndicatorResult, TypeOrmHealthIndicator } from '@nestjs/terminus';

@Injectable()
export class PostgresHealthIndicator extends HealthIndicator {
  constructor(private readonly dbIndicator: TypeOrmHealthIndicator) {
    super();
  }

  async isHealthy(key: string): Promise<HealthIndicatorResult> {
    try {
      await this.dbIndicator.pingCheck('database');
      return this.getStatus(key, true);
    } catch (err: any) {
      return this.getStatus(key, false, { message: err.message });
    }
  }
}
