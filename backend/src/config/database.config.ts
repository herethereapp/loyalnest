import { TypeOrmModuleOptions } from '@nestjs/typeorm';

function getEnvVariable(name: string, defaultValue?: string): string {
  const value = process.env[name] || defaultValue;
  if (value === undefined) {
    throw new Error(`Environment variable ${name} is not defined`);
  }
  return value;
}

export const databaseConfig: TypeOrmModuleOptions = {
  type: 'postgres',
  host: getEnvVariable('POSTGRES_HOST', 'localhost'),
  port: parseInt(getEnvVariable('POSTGRES_PORT', '5432'), 10),
  username: getEnvVariable('POSTGRES_USER', 'postgres'),
  password: getEnvVariable('POSTGRES_PASSWORD', 'postgres'),
  database: getEnvVariable('POSTGRES_DB', 'shopify_app'),
  entities: [__dirname + '/../**/*.entity{.ts,.js}'],
  synchronize: process.env.NODE_ENV !== 'production', // Disable in production
};