import React from 'react';
import {Flex} from 'theme-ui';
import {notification, Button, Text} from '../common';
import * as API from '../../api';
import {Customer} from '../../types';
import logger from '../../logger';
import {DetailsSectionCard} from '../conversations/ConversationDetailsSidebar';

export const CustomerHubspotInfo = ({customer}: {customer: Customer}) => {
  const [status, setStatus] = React.useState<
    'loading' | 'adding' | 'success' | 'error'
  >('loading');
  const [authorization, setHubspotAuthorization] = React.useState<any>(null);
  const [hubspotContactInfo, setHubspotContactInfo] = React.useState<any>(null);
  const {email} = customer;

  React.useEffect(() => {
    if (!email) {
      return;
    }

    setStatus('loading');

    API.fetchHubspotAuthorization()
      .then((auth) => {
        setHubspotAuthorization(auth);

        if (auth) {
          return API.fetchHubspotContactByEmail(email);
        } else {
          return null;
        }
      })
      .then((contact) => setHubspotContactInfo(contact))
      .catch((err) => logger.error('Error retrieving HubSpot contact:', err))
      .then(() => setStatus('success'));
  }, [email]);

  function handleCreateHubspotContact() {
    const {name, email, phone} = customer;

    if (!email) {
      return;
    }

    setStatus('adding');

    const [firstName, lastName] = (name || '').split(' ');
    const payload = {
      email,
      phone,
      first_name: firstName,
      last_name: lastName,
    };

    return API.createHubspotContact(payload)
      .then((contact) => {
        setHubspotContactInfo(contact);

        const url = contact?.hubspot_profile_url;

        notification.success({
          message: `Successfully added to HubSpot.`,
          description: url ? (
            <Text>
              Click{' '}
              <a href={url} target="_blank" rel="noopener noreferrer">
                here
              </a>{' '}
              to view in HubSpot.
            </Text>
          ) : null,
        });
      })

      .catch((err) =>
        logger.error('Error creating/retrieving HubSpot contact:', err)
      )
      .then(() => setStatus('success'));
  }

  if (!email) {
    return null;
  }

  const url = hubspotContactInfo?.hubspot_profile_url;

  if (!url && !authorization) {
    return null;
  }

  return (
    <DetailsSectionCard>
      <Flex mb={2} sx={{}}>
        <img
          src="/hubspot.svg"
          alt="HubSpot"
          style={{maxHeight: 20, maxWidth: 20, marginRight: 4}}
        />

        <Text strong>HubSpot</Text>
      </Flex>
      {url ? (
        <a href={url} target="_blank" rel="noopener noreferrer">
          <Button block>View HubSpot profile</Button>
        </a>
      ) : (
        <Button
          block
          disabled={status === 'loading'}
          loading={status === 'adding'}
          onClick={handleCreateHubspotContact}
        >
          {status === 'loading' ? 'Loading...' : 'Add to HubSpot'}
        </Button>
      )}
    </DetailsSectionCard>
  );
};

export default CustomerHubspotInfo;
