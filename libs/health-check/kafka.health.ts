// libs/health-check/kafka.health.ts
import { Injectable } from '@nestjs/common';
import { HealthIndicator, HealthIndicatorResult } from '@nestjs/terminus';
import { Kafka, Admin } from 'kafkajs';

@Injectable()
export class KafkaHealthIndicator extends HealthIndicator {
  private admin: Admin;

  constructor() {
    super();
    const kafka = new Kafka({
      clientId: 'health-check',
      brokers: [process.env.KAFKA_BROKER || 'localhost:9092'],
    });
    this.admin = kafka.admin();
  }

  async isHealthy(key: string): Promise<HealthIndicatorResult> {
    try {
      await this.admin.connect();
      await this.admin.listTopics();
      await this.admin.disconnect();
      return this.getStatus(key, true);
    } catch (err: any) {
      return this.getStatus(key, false, { message: err.message });
    }
  }
}
