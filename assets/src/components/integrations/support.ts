export type IntegrationType = {
  key:
    | 'slack'
    | 'slack:sync'
    | 'mattermost'
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
