export type Account = {
  id: string;
  company_name: string;
  time_zone?: string;
  subscription_plan?: string;
  users?: Array<User>;
  widget_settings: any;
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
};

export type MessageType = 'reply' | 'note';

export type Message = {
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

export enum Alignment {
  Right = 'right',
  Left = 'left',
  Center = 'center',
}
