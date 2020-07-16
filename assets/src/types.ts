// NB: actual message records will look slightly different
export type Message = {
  sender: string;
  body: string;
  created_at: string;
  customer_id: string;
  conversation_id: string;
};

// NB: actual conversation records will look different
export type Conversation = {
  id: string;
  customer: string;
  date: string;
  preview: string;
  messages?: Array<Message>;
};
