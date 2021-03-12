export type Account = {
  id: string;
  company_name: string;
  time_zone?: string;
  subscription_plan?: string;
  users?: Array<User>;
  widget_settings: WidgetSettings;
  working_hours: Array<any>;
};

export type User = {
  id: number;
  email: string;
  display_name?: string;
  full_name?: string;
  profile_photo_url?: string;
  created_at?: string;
  disabled_at?: string;
  role?: 'user' | 'admin';
  account_id?: string;
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
  last_seen?: string;
  metadata?: any;
  os?: string;
  pathname?: string;
  phone?: number;
  tags?: Array<Tag>;
  time_zone?: string;
  updated_at?: string;
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
  type?: 'reply' | 'note';
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

export type Conversation = {
  id: string;
  source?: string;
  account_id: string;
  customer_id: string;
  customer: Customer;
  created_at?: string;
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
};

export type Tag = {
  id: string;
  name: string;
  description?: string;
  color?: string;
  updated_at: string;
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
