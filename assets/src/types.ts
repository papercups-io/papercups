export type User = {
  id: number;
  email: string;
};

export type Customer = {
  id: number;
  email?: string;
  name?: string;
};

// NB: actual message records will look slightly different
export type Message = {
  body: string;
  created_at: string;
  customer_id?: string;
  conversation_id: string;
  user_id?: string;
  user?: User;
};

// NB: actual conversation records will look different
export type Conversation = {
  id: string;
  customer: string;
  date: string;
  preview: string;
  messages?: Array<Message>;
  priority?: string;
  read?: boolean;
  status?: string;
  assignee_id?: number;
};
