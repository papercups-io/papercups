import React from 'react';
import {Box} from 'theme-ui';
import {Container, Paragraph, Title} from '../common';
import {NewCustomerButton} from './NewCustomerModal';
import CustomersTableContainer from './CustomersTableContainer';

const CustomersPage = () => {
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
          includeTagFilterInput
          actions={(onSuccess) => <NewCustomerButton onSuccess={onSuccess} />}
        />
      </Box>
    </Container>
  );
};

export default CustomersPage;
