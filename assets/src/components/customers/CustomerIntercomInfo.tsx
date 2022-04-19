import React from 'react';
import {Flex} from 'theme-ui';
import {notification, Button, Text} from '../common';
import * as API from '../../api';
import {Customer} from '../../types';
import logger from '../../logger';
import {DetailsSectionCard} from '../conversations/ConversationDetailsSidebar';

const getIntercomCustomerUrl = (contact: any) => {
  if (!contact || !contact.id || !contact.workspace_id) {
    return null;
  }

  const {id: contactId, workspace_id: workspaceId} = contact;

  return `https://app.intercom.com/a/apps/${workspaceId}/users/${contactId}`;
};

export const CustomerIntercomInfo = ({customer}: {customer: Customer}) => {
  const [status, setStatus] = React.useState<
    'loading' | 'adding' | 'success' | 'error'
  >('loading');
  const [authorization, setIntercomAuthorization] = React.useState<any>(null);
  const [intercomContactInfo, setIntercomContactInfo] = React.useState<any>(
    null
  );
  const {email} = customer;

  React.useEffect(() => {
    if (!email) {
      return;
    }

    setStatus('loading');

    API.fetchIntercomAuthorization()
      .then((auth) => {
        setIntercomAuthorization(auth);

        if (auth) {
          return API.fetchIntercomContactByEmail(email);
        } else {
          return null;
        }
      })
      .then((contact) => setIntercomContactInfo(contact))
      .catch((err) => logger.error('Error retrieving HubSpot contact:', err))
      .then(() => setStatus('success'));
  }, [email]);

  function handleCreateIntercomContact() {
    const {name, email, phone, external_id} = customer;

    if (!email) {
      return;
    }

    setStatus('adding');

    const payload = {
      email,
      phone,
      name,
      external_id,
      role: 'user',
    };

    return API.createIntercomContact(payload)
      .then((contact) => {
        setIntercomContactInfo(contact);

        const url = getIntercomCustomerUrl(contact);

        notification.success({
          message: `Successfully added to Intercom.`,
          description: url ? (
            <Text>
              Click{' '}
              <a href={url} target="_blank" rel="noopener noreferrer">
                here
              </a>{' '}
              to view in Intercom.
            </Text>
          ) : null,
        });
      })

      .catch((err) =>
        logger.error('Error creating/retrieving Intercom contact:', err)
      )
      .then(() => setStatus('success'));
  }

  if (!email) {
    return null;
  }

  const url = getIntercomCustomerUrl(intercomContactInfo);

  if (!url && !authorization) {
    return null;
  }

  return (
    <DetailsSectionCard>
      <Flex mb={2} sx={{}}>
        <img
          src="/intercom.svg"
          alt="Intercom"
          style={{maxHeight: 20, maxWidth: 20, marginRight: 4}}
        />

        <Text strong>Intercom</Text>
      </Flex>
      {url ? (
        <a href={url} target="_blank" rel="noopener noreferrer">
          <Button block>View Intercom profile</Button>
        </a>
      ) : (
        <Button
          block
          disabled={status === 'loading'}
          loading={status === 'adding'}
          onClick={handleCreateIntercomContact}
        >
          {status === 'loading' ? 'Loading...' : 'Add to Intercom'}
        </Button>
      )}
    </DetailsSectionCard>
  );
};

export default CustomerIntercomInfo;
