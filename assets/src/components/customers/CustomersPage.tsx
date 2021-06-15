import React from 'react';
import {Box} from 'theme-ui';
import {Container, Paragraph, Title} from '../common';
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
    <Container>
      <Box mb={5}>
        <Title level={3}>Customers</Title>

        <Box mb={4}>
          <Paragraph>
            View the people that have interacted with you most recently and have
            provided an email address.
          </Paragraph>
        </Box>

        <CustomersTableContainer
          currentlyOnline={online}
          includeTagFilterInput
          actions={(onSuccess) => <NewCustomerButton onSuccess={onSuccess} />}
        />
      </Box>
    </Container>
  );
};

export default CustomersPage;
