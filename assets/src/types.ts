export type Account = {
  id: string;
  company_name: string;
  company_logo_url?: string;
  time_zone?: string;
  subscription_plan?: string;
  users?: Array<User>;
  widget_settings: WidgetSettings;
  working_hours: Array<any>;
  settings?: AccountSettings | null;
};

export type AccountSettings = {
  disable_automated_reply_emails?: boolean | null;
  conversation_reminders_enabled?: boolean | null;
  conversation_reminder_hours_interval?: number | null;
  max_num_conversation_reminders?: number | null;
};

export type User = {
  id: number;
  email: string;
  display_name?: string;
  full_name?: string;
  profile_photo_url?: string;
  created_at?: string;
  disabled_at?: string;
  role: 'user' | 'admin';
  account_id: string;
};

export type Customer = {
  id: string;
  email?: string;
  name?: string;
  browser?: string;
  created_at?: string;
  current_url?: string;
  external_id?: any;
  profile_photo_url?: string;
  first_seen?: any;
  host?: string;
  ip?: string;
  // Datetime
  last_seen_at: string;
  metadata?: any;
  os?: string;
  pathname?: string;
  phone?: string | number;
  tags?: Array<Tag>;
  time_zone?: string;
  updated_at?: string;
  title: string;
  // Associations
  company?: Company;
  conversations?: Array<Conversation>;
};

export type Company = {
  id: string;
  name: string;
  description?: string;
  website_url?: string;
  external_id?: string;
  slack_channel_id?: string;
  slack_channel_name?: string;
  updated_at: string;
};

export type MessageType = 'reply' | 'note';

export type Message = {
  id: string;
  body: string;
  type?: 'reply' | 'note' | 'bot';
  private?: boolean;
  created_at: string;
  sent_at?: string;
  seen_at?: string;
  customer_id?: string;
  customer?: Customer;
  conversation_id: string;
  user_id?: number;
  user?: User;
  file_ids?: string[];
  attachments?: Attachment[];
};

export type FileUpload = {
  id: string;
  filename: string;
  file_url: string;
  content_type: string;
};

// Alias
export type Attachment = FileUpload;

export type ConversationSource = 'chat' | 'email' | 'slack' | 'sms';

export type Conversation = {
  id: string;
  source?: ConversationSource;
  subject?: string;
  account_id: string;
  customer_id: string;
  customer: Customer;
  created_at?: string;
  last_activity_at?: string;
  date: string;
  preview: string;
  messages?: Array<Message>;
  priority?: string;
  read?: boolean;
  status?: string;
  assignee_id?: number;
  tags?: Array<Tag>;
};

export type CustomerNote = {
  id: string;
  body: string;
  customer_id: string;
  author_id: number;
  created_at: string;
  updated_at: string;
  author?: User;
  customer?: Customer;
};

export type Tag = {
  id: string;
  name: string;
  description?: string;
  color?: string;
  updated_at: string;
};

export type IssueState =
  | 'unstarted'
  | 'in_progress'
  | 'in_review'
  | 'done'
  | 'closed';

export type Issue = {
  id: string;
  title: string;
  body?: string;
  state: IssueState;
  github_issue_url?: string;
  created_at: string;
  updated_at: string;
};

export type LambdaStatus = 'pending' | 'active' | 'inactive';

export type Lambda = {
  id: string;
  object: 'lambda';
  account_id: string;
  name: string;
  description?: string;
  code?: string;
  language?: string;
  runtime?: string;
  status: LambdaStatus;
  last_deployed_at?: string;
  last_executed_at?: string;
  created_at: string;
  updated_at: string;
  metadata?: string;
};

export type BrowserSession = {
  id: string;
  started_at: string;
  finished_at?: string;
  metadata?: any;
  // Client-side properties
  active?: boolean;
  ts?: string | Date;
};

export type EventSubscription = {
  id?: string;
  webhook_url: string;
  verified: boolean;
  created_at?: string | null;
};

export type PersonalApiKey = {
  id?: string;
  label: string;
  value: string;
  created_at?: string | null;
};

export type MattermostAuthorization = {
  id?: string;
  access_token?: string;
  channel_id?: string;
  channel_name?: string;
  team_id?: string;
  team_domain?: string;
  verification_token?: string;
  mattermost_url?: string;
};

export type MattermostChannel = {
  display_name: string;
  id: string;
  name: string;
  purpose: string;
  team_display_name: string;
  team_id: string;
  team_name: string;
};

export type TwilioAuthorization = {
  id?: string;
  twilio_auth_token?: string;
  twilio_account_sid?: string;
  from_phone_number?: string;
};

export type WidgetIconVariant = 'outlined' | 'filled';

export type WidgetSettings = {
  id?: string;
  title?: string;
  subtitle?: string;
  color?: string;
  greeting?: string;
  away_message?: string;
  new_message_placeholder?: string;
  show_agent_availability?: boolean;
  agent_available_text?: string;
  agent_unavailable_text?: string;
  require_email_upfront?: boolean;
  is_open_by_default?: boolean;
  custom_icon_url?: string;
  iframe_url_override?: string;
  icon_variant?: WidgetIconVariant;
  email_input_placeholder?: string;
  new_messages_notification_text?: string;
  base_url?: string;
  host?: string;
  pathname?: string;
  last_seen_at: string | null;
  account_id: string;
  inserted_at: string | null;
  updated_at: string | null;
};

export enum Alignment {
  Right = 'right',
  Left = 'left',
  Center = 'center',
}

export type Pagination = {
  page_size: number;
  page_number: number;
  total_pages?: number;
  total_entries?: number;
};

export type GoogleIntegrationClient = 'gmail' | 'sheets';
export type GoogleIntegrationType = 'personal' | 'support';
export type GoogleIntegrationParams = {
  client: GoogleIntegrationClient;
  type?: GoogleIntegrationType;
};

export type GoogleAuthParams = {
  code: string;
  state?: string | null;
  scope?: string | null;
};

export type SlackAuthorizationSettings = {
  sync_all_incoming_threads: boolean;
  sync_by_emoji_tagging: boolean;
  sync_trigger_emoji: string;
  forward_synced_messages_to_reply_channel: boolean;
};

export type SlackAuthorization = {
  id: string;
  created_at: string;
  channel: string;
  configuration_url: string;
  team_name: string;
  settings: SlackAuthorizationSettings | null;
};

export type OnboardingStatus = {
  has_configured_profile: boolean;
  has_configured_storytime: boolean;
  has_integrations: boolean;
  is_chat_widget_installed: boolean;
  has_invited_teammates: boolean;
  has_upgraded_subscription: boolean;
};
