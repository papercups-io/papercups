export type IntegrationType = {
  key: 'slack' | 'gmail';
  integration: string;
  status: 'connected' | 'not_connected';
  created_at?: string | null;
  icon: string;
};

export type WebhookEventSubscription = {
  id?: string;
  webhook_url: string;
  verified: boolean;
  created_at?: string | null;
};
