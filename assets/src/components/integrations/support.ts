export type IntegrationType = {
  key:
    | 'slack'
    | 'slack:sync'
    | 'gmail'
    | 'sheets'
    | 'microsoft-teams'
    | 'whatsapp'
    | 'twilio';
  integration: string;
  status: 'connected' | 'not_connected';
  created_at?: string | null;
  authorization_id: string | null;
  icon: string;
  description?: string;
};

export type WebhookEventSubscription = {
  id?: string;
  webhook_url: string;
  verified: boolean;
  created_at?: string | null;
};
