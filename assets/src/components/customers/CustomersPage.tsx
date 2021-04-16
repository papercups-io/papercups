import React from 'react';
import {Box} from 'theme-ui';
import {Alert, Paragraph, Text, Title} from '../common';
import {useConversations} from '../conversations/ConversationsProvider';
import {NewCustomerButton} from './NewCustomerModal';
import CustomersTableContainer from './CustomersTableContainer';

const CustomersPage = () => {
  const {currentlyOnline = {}} = useConversations();
  const online = Object.keys(currentlyOnline).reduce((acc, key: string) => {
    const [prefix, id] = key.split(':');

    if (prefix === 'customer' && !!id) {
      return {...acc, [id]: true};
    }

    return acc;
  }, {} as {[key: string]: boolean});

  return (
    <Box p={4} sx={{maxWidth: 1080}}>
      <Box mb={5}>
        <Title level={3}>Customers (beta)</Title>

        <Box mb={4}>
          <Paragraph>
            View the people that have interacted with you most recently and have
            provided an email address.
          </Paragraph>

          <Alert
            message={
              <Text>
                This page is still a work in progress &mdash; more features
                coming soon!
              </Text>
            }
            type="info"
            showIcon
          />
        </Box>

        <CustomersTableContainer
          currentlyOnline={online}
          actions={(onSuccess) => <NewCustomerButton onSuccess={onSuccess} />}
        />
      </Box>
    </Box>
  );
};

export default CustomersPage;
