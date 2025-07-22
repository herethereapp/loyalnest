import { shopifyApi } from '@shopify/shopify-api';

export const shopifyConfig = {
  apiKey: process.env.SHOPIFY_API_KEY,
  apiSecretKey: process.env.SHOPIFY_API_SECRET,
  scopes: ['read_products', 'write_products'], // Adjust scopes as needed
  hostName: 'localhost:3000',
  apiVersion: '2024-04',
};

export const shopify = shopifyApi({
  apiKey: shopifyConfig.apiKey!,
  apiSecretKey: shopifyConfig.apiSecretKey!,
  scopes: shopifyConfig.scopes,
  hostName: shopifyConfig.hostName,
  apiVersion: shopifyConfig.apiVersion as any,
  isEmbeddedApp: true,
});