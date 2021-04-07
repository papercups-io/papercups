import * as API from '../../api';
import logger from '../../logger';
import {download} from '../../utils';

export const exportCustomerData = async (customerId: string) => {
  try {
    const customer = await API.fetchCustomer(customerId, {
      expand: ['company', 'conversations', 'messages', 'tags', 'notes'],
    });

    download(customer, `customer-${customerId}`);
  } catch (err) {
    logger.error('Failed to export customer:', err);
  }
};
