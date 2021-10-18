import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Broadcast} from '../../types';

dayjs.extend(utc);

export const formatDateTime = (datetime: string) => {
  return dayjs(datetime).format('MMM D, YYYY hh:mm a');
};

export type FormattedBroadcastCustomer = {
  key: string;
  created_at: string;
  updated_at: string;
  state: string;
  sent_at?: string | null;
  name: string;
  email: string;
  time_zone: string;
  metadata: any;
};

export const formatBroadcastCustomers = (
  broadcast: Broadcast
): Array<FormattedBroadcastCustomer> => {
  const {broadcast_customers: broadcastCustomers = []} = broadcast;

  return broadcastCustomers.map((bc: any) => {
    const {
      customer = {},
      id: key,
      customer_id,
      broadcast_id,
      created_at,
      updated_at,
      sent_at,
      state,
    } = bc;
    const {name, email, time_zone, metadata = {}} = customer;

    return {
      key,
      customer_id,
      broadcast_id,
      created_at,
      updated_at,
      state,
      sent_at,
      name,
      email,
      time_zone,
      metadata,
    };
  });
};
