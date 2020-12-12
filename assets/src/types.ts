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

// NB: actual message records will look slightly different
export type Message = {
  body: string;
  created_at: string;
  sent_at?: string;
  seen_at?: string;
  customer_id?: string;
  conversation_id: string;
  user_id?: number;
  user?: User;
};

// NB: actual conversation records will look different
export type Conversation = {
  id: string;
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
